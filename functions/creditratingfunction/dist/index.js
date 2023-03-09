/**
 * Describe CreditRatingFunction here.
 *
 * The exported method is the entry point for your code when the function is invoked.
 *
 * Following parameters are pre-configured and provided to your function on execution:
 * @param event: representative of the data associated with the occurrence of an event,
 * and supporting metadata about the source of that occurrence.
 * @param context: represents the connection to the the execution environment and the Customer 360 instance that
 * the function is associated with.
 * @param logger: represents the logging functionality to log given messages at various levels
 */
export default async function execute(event, context, logger) {
    logger.info(`Invoking CreditRatingFunction with payload ${JSON.stringify(event.data || {})}`);
    // Log payload's accountId
    const account = event.data;
    logger.info(JSON.stringify(account.id));
    // Generate random credit rating between 500 and 800
    const creditRating = { rating: `${Math.floor(Math.random() * (800 - 500 + 1) + 500)}` };
    return creditRating;
}
//# sourceMappingURL=index.js.map