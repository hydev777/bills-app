import 'package:equatable/equatable.dart';

/// Result type for operations that can succeed or fail.
/// Use top-level [success] / [failure] or [Success] / [Err] to create instances.
sealed class Result<T, E> extends Equatable {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) {
    return switch (this) {
      Success<T, E>(:final value) => success(value),
      Err<T, E>(:final error) => failure(error),
    };
  }

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onFailure,
  }) =>
      when(success: onSuccess, failure: onFailure);

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Err<T, E>;

  T? get valueOrNull =>
      switch (this) { Success<T, E>(:final value) => value, _ => null };
  E? get errorOrNull =>
      switch (this) { Err<T, E>(:final error) => error, _ => null };
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.value);
  final T value;

  @override
  List<Object?> get props => [value];
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;

  @override
  List<Object?> get props => [error];
}

/// Create a successful result.
Result<T, E> success<T, E>(T value) => Success<T, E>(value);

/// Create a failed result (E is typically [Failure] from failures.dart).
Result<T, E> failure<T, E>(E error) => Err<T, E>(error);
