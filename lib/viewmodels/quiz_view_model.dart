import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/exceptions/api_exception.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../models/quiz_result_model.dart';
import '../models/start_quiz_response_model.dart';
import '../services/quiz_service.dart';

class QuizViewModel extends ChangeNotifier {
  QuizViewModel({required QuizService quizService})
      : _quizService = quizService;

  final QuizService _quizService;

  List<QuizModel> _quizzes = [];
  bool _isLoadingQuizList = false;
  bool _isStartingQuiz = false;
  bool _isLoadingQuestion = false;
  bool _isSubmittingQuiz = false;
  bool _isExitingQuiz = false;
  bool _isGeneratingCertificate = false;
  String? _errorMessage;
  bool _sessionExpired = false;

  StartQuizResponseModel? _activeAttempt;
  QuizQuestionModel? _currentQuestion;
  QuizResultModel? _quizResult;
  final Map<int, String> _selectedAnswers = {};
  final Map<int, QuizQuestionModel> _questionCache = {};

  int _currentQuestionNumber = 1;
  int? _activeQuizId;
  int? _startingQuizId;
  int? _failedQuestionNumber;
  DateTime? _endDateTime;
  Duration _remainingTime = Duration.zero;
  Timer? _countdownTimer;
  bool _timeExpired = false;
  bool _autoSubmitStarted = false;
  int _latestStreakCount = 0;

  List<QuizModel> get quizzes => List.unmodifiable(_quizzes);
  bool get isLoadingQuizList => _isLoadingQuizList;
  bool get isStartingQuiz => _isStartingQuiz;
  bool get isLoadingQuestion => _isLoadingQuestion;
  bool get isSubmittingQuiz => _isSubmittingQuiz;
  bool get isExitingQuiz => _isExitingQuiz;
  bool get isGeneratingCertificate => _isGeneratingCertificate;
  String? get errorMessage => _errorMessage;
  bool get sessionExpired => _sessionExpired;

  StartQuizResponseModel? get activeAttempt => _activeAttempt;
  QuizQuestionModel? get currentQuestion => _currentQuestion;
  QuizResultModel? get quizResult => _quizResult;
  Map<int, String> get selectedAnswers =>
      Map.unmodifiable(_selectedAnswers);
  int get currentQuestionNumber => _currentQuestionNumber;
  int? get activeQuizId => _activeQuizId;
  int? get startingQuizId => _startingQuizId;
  int? get failedQuestionNumber => _failedQuestionNumber;
  DateTime? get endDateTime => _endDateTime;
  Duration get remainingTime => _remainingTime;
  bool get timeExpired => _timeExpired;
  int get latestStreakCount => _latestStreakCount;

  int get totalQuestions => _activeAttempt?.totalQuestions ?? 0;

  double get questionProgress {
    if (totalQuestions <= 0) return 0;
    return (_currentQuestionNumber / totalQuestions).clamp(0.0, 1.0);
  }

  int get answeredCount => _selectedAnswers.length;

  int get passedQuizCount =>
      _quizzes.where((quiz) => quiz.lastAttemptSuccessfull).length;

  double get quizListProgress {
    if (_quizzes.isEmpty) return 0;
    return (passedQuizCount / _quizzes.length).clamp(0.0, 1.0);
  }

  bool get isLastQuestion =>
      totalQuestions > 0 && _currentQuestionNumber >= totalQuestions;

  bool get canSelectAnswer =>
      !_timeExpired && !_isSubmittingQuiz && !_isExitingQuiz;

  Future<void> loadQuizzes() async {
    _isLoadingQuizList = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quizzes = await _quizService.getAllQuizzes();
    } catch (error) {
      _handleError(error);
    } finally {
      _isLoadingQuizList = false;
      notifyListeners();
    }
  }

  Future<bool> startQuiz(int quizId) async {
    _isStartingQuiz = true;
    _startingQuizId = quizId;
    _errorMessage = null;
    _quizResult = null;
    notifyListeners();

    try {
      final response = await _quizService.startQuiz(quizId);
      _resetActiveState(keepResult: false);

      _activeQuizId = quizId;
      _activeAttempt = response;
      _currentQuestion = response.firstQuestion;
      _currentQuestionNumber =
          response.firstQuestion.currentNumber <= 0
              ? 1
              : response.firstQuestion.currentNumber;
      _questionCache[_currentQuestionNumber] = response.firstQuestion;
      _endDateTime = response.endDateTime;
      _startCountdown();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _isStartingQuiz = false;
      _startingQuizId = null;
      notifyListeners();
    }
  }

  Future<void> loadQuestion(
    int quizId,
    int questionNumber,
  ) async {
    if (questionNumber < 1 || questionNumber > totalQuestions) return;

    _errorMessage = null;
    _failedQuestionNumber = null;

    final cached = _questionCache[questionNumber];
    if (cached != null) {
      _currentQuestionNumber = questionNumber;
      _currentQuestion = cached;
      notifyListeners();
      return;
    }

    _isLoadingQuestion = true;
    notifyListeners();

    try {
      final question = await _quizService.getQuizQuestion(
        quizId,
        questionNumber,
      );
      _questionCache[questionNumber] = question;
      _currentQuestionNumber = questionNumber;
      _currentQuestion = question;
    } catch (error) {
      // currentQuestion dan selectedAnswers sengaja tidak dihapus.
      _failedQuestionNumber = questionNumber;
      _handleError(error);
    } finally {
      _isLoadingQuestion = false;
      notifyListeners();
    }
  }

  void selectAnswer(int questionId, String answer) {
    if (!canSelectAnswer) return;

    final normalized = answer.toLowerCase();
    if (!const {'a', 'b', 'c', 'd'}.contains(normalized)) return;

    _selectedAnswers[questionId] = normalized;
    notifyListeners();
  }

  String? getSelectedAnswer(int questionId) {
    return _selectedAnswers[questionId];
  }

  Future<bool> submitQuiz(int quizId) async {
    if (_isSubmittingQuiz) return false;

    _isSubmittingQuiz = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _quizService.submitQuiz(
        quizId,
        _selectedAnswers,
      );

      _quizResult = result;
      _latestStreakCount = result.streakCount;
      _stopCountdown();
      await _refreshQuizzesSilently();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _isSubmittingQuiz = false;
      notifyListeners();
    }
  }

  Future<bool> exitQuiz(int quizId) async {
    if (_isExitingQuiz) return false;

    _isExitingQuiz = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _quizService.exitQuizEarly(quizId);
      _resetActiveState(keepResult: false);
      await _refreshQuizzesSilently();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _isExitingQuiz = false;
      notifyListeners();
    }
  }

  Future<String?> generateCertificate(int quizId) async {
    if (_isGeneratingCertificate) return null;

    _isGeneratingCertificate = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _quizService.generateCertificate(quizId);
      if (response.certificateId.isEmpty) {
        throw const ApiException('ID sertifikat tidak valid.');
      }

      if (_quizResult != null) {
        _quizResult = _quizResult!.copyWith(
          certificateId: response.certificateId,
        );
      }

      await _refreshQuizzesSilently();
      return response.certificateId;
    } catch (error) {
      _handleError(error);
      return null;
    } finally {
      _isGeneratingCertificate = false;
      notifyListeners();
    }
  }

  void clearActiveQuiz({bool keepResult = false}) {
    _resetActiveState(keepResult: keepResult);
    notifyListeners();
  }

  bool consumeSessionExpired() {
    if (!_sessionExpired) return false;
    _sessionExpired = false;
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _startCountdown() {
    _stopCountdown();
    _timeExpired = false;
    _autoSubmitStarted = false;
    _updateRemainingTime();

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemainingTime(),
    );
  }

  void _updateRemainingTime() {
    final end = _endDateTime;
    if (end == null) {
      _remainingTime = Duration.zero;
      return;
    }

    final remaining = end.toUtc().difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      _remainingTime = Duration.zero;
      _timeExpired = true;
      _stopCountdown();
      notifyListeners();

      if (!_autoSubmitStarted && _activeQuizId != null) {
        _autoSubmitStarted = true;
        unawaited(submitQuiz(_activeQuizId!));
      }
      return;
    }

    _remainingTime = remaining;
    notifyListeners();
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _refreshQuizzesSilently() async {
    try {
      _quizzes = await _quizService.getAllQuizzes();
    } catch (error) {
      if (error is SessionExpiredException) {
        _handleError(error);
      }
      // Kegagalan refresh tidak membatalkan submit/generate yang sudah sukses.
    }
  }

  void _handleError(Object error) {
    if (error is SessionExpiredException) {
      _sessionExpired = true;
      _errorMessage = error.message;
      return;
    }

    if (error is ApiException) {
      _errorMessage = error.message;
      return;
    }

    _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
  }

  void _resetActiveState({required bool keepResult}) {
    _stopCountdown();
    _activeAttempt = null;
    _currentQuestion = null;
    _selectedAnswers.clear();
    _questionCache.clear();
    _currentQuestionNumber = 1;
    _activeQuizId = null;
    _failedQuestionNumber = null;
    _endDateTime = null;
    _remainingTime = Duration.zero;
    _timeExpired = false;
    _autoSubmitStarted = false;
    if (!keepResult) _quizResult = null;
  }

  @override
  void dispose() {
    _stopCountdown();
    _quizService.dispose();
    super.dispose();
  }
}
