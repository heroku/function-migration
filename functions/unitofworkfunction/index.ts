import { InvocationEvent, Context, Logger } from "sf-fx-sdk-nodejs";

/**
 * Receives a payload containing Account, Contact, and Case details and uses the
 * Unit of Work pattern to assign the corresponding values to to its Record
 * while maintaining the relationships. It then commits the unit of work and
 * returns the Record Id's for each object.
 *
 * The exported method is the entry point for your code when the function is invoked.
 *
 * Following parameters are pre-configured and provided to your function on execution:
 * @param event: represents the data associated with the occurrence of an event, and
 *                 supporting metadata about the source of that occurrence.
 * @param context: represents the connection to Functions and your Salesforce org.
 * @param logger: logging handler used to capture application logs and trace specifically
 *                 to a given execution of a function.
 */
 export default async function execute(event: InvocationEvent<any>, context: Context, logger: Logger): Promise<any> {
    logger.info(
      `Yo!!! Invoking unitofworkjs Function with payload ${JSON.stringify(
        event.data || {}
      )}`
    );

    // TODO: Invoke /services/oauth2/userinfo to verify user
  
    const query = "SELECT Id, Name FROM Account";
    //logger.info(query);
    const results:any = await context.org.dataApi.query(query);
    logger.info(JSON.stringify(results));
    return results.records;
}
