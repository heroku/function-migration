package com.example;

import com.salesforce.functions.jvm.sdk.Context;
import com.salesforce.functions.jvm.sdk.InvocationEvent;
import com.salesforce.functions.jvm.sdk.SalesforceFunction;
import com.salesforce.functions.jvm.sdk.data.Record;
import com.salesforce.functions.jvm.sdk.data.RecordWithSubQueryResults;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

/**
 * Describe JavafunctionFunction here.
 */
public class JavafunctionFunction implements SalesforceFunction<FunctionInput, FunctionOutput> {
  private static final Logger LOGGER = LoggerFactory.getLogger(JavafunctionFunction.class);

  @Override
  public FunctionOutput apply(InvocationEvent<FunctionInput> event, Context context)
      throws Exception {

    List<RecordWithSubQueryResults> records =
        context.getOrg().get().getDataApi().query("SELECT Id, Name FROM Account").getRecords();

    LOGGER.info("Function successfully queried {} account records!", records.size());

    List<Account> accounts = new ArrayList<>();
    for (Record record : records) {
      String id = record.getStringField("Id").get();
      String name = record.getStringField("Name").get();

      accounts.add(new Account(id, name));
    }

    return new FunctionOutput(accounts);
  }
}
