/// A field's relative size, as suggested by the server's `style.size` hint.
///
/// This lives in Domain — not `core/design_system` — because Domain must not
/// depend on anything (see architecture: Domain is the shared inward target,
/// it imports nothing). Presentation, the only layer allowed to see both
/// Domain and the design system, maps this onto `DsFieldSize` when building
/// widgets. Keeping the two enums separate also means a server-side renaming
/// of size hints never forces a change to design-system component code.
enum FieldSizeHint { small, medium, large }
