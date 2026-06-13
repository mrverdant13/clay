/**
 * Polls [predicate] until it returns true or [timeoutMs] elapses.
 *
 * @param {() => boolean | Promise<boolean>} predicate
 * @param {number} [timeoutMs]
 * @param {number} [intervalMs]
 */
async function waitFor(predicate, timeoutMs = 30_000, intervalMs = 100) {
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    if (await predicate()) {
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, intervalMs));
  }

  throw new Error(`Timed out after ${timeoutMs}ms`);
}

module.exports = { waitFor };
