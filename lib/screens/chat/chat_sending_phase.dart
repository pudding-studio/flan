/// Lifecycle phases of a chat-room send operation.
///
/// `none` is the idle state. The other values drive UI affordances such as
/// the input hint text and the send button's loading indicator.
enum SendingPhase { none, preparing, waiting, summarizing }
