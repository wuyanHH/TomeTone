/// 书库批量刷新状态。
class BatchRefreshState {
  final bool isRunning;
  final int total;
  final int completed;
  final int updatedCount;
  final String? currentBookTitle;
  final String? message;

  const BatchRefreshState({
    this.isRunning = false,
    this.total = 0,
    this.completed = 0,
    this.updatedCount = 0,
    this.currentBookTitle,
    this.message,
  });

  BatchRefreshState copyWith({
    bool? isRunning,
    int? total,
    int? completed,
    int? updatedCount,
    String? currentBookTitle,
    String? message,
  }) {
    return BatchRefreshState(
      isRunning: isRunning ?? this.isRunning,
      total: total ?? this.total,
      completed: completed ?? this.completed,
      updatedCount: updatedCount ?? this.updatedCount,
      currentBookTitle: currentBookTitle ?? this.currentBookTitle,
      message: message ?? this.message,
    );
  }

  double get progressRatio => total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
}
