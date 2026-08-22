/// Everything that can go wrong fetching or submitting a form, as a sealed
/// hierarchy.
///
/// Lives in Domain — not Data, not a `core` error type — because it has to
/// be importable by Presentation (to pattern-match into the right error
/// state/message) without Presentation ever importing Data. Domain is the
/// only layer every other layer is allowed to depend on, so a type everyone
/// needs to read has to live here. Data produces `Either<Failure, T>`
/// (fpdart) at the repository boundary; no raw `try`/`catch` crosses into
/// Application.
sealed class Failure {
  const Failure();
}

/// No connectivity, DNS failure, connection refused — the request never
/// reached a server.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// The request reached a server but didn't get a response in time.
final class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

/// The server responded with an error status.
final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode);
  final int statusCode;
}

/// The response body didn't match the expected shape (malformed JSON, a
/// missing required key, a field of the wrong type).
final class ParseFailure extends Failure {
  const ParseFailure(this.details);
  final String details;
}

/// Anything else — caught at the repository boundary so it never crosses
/// into Application as a raw exception.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(this.details);
  final String details;
}
