/**
 * Copyright (c) 2016, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root  or https://opensource.org/licenses/BSD-3-Clause
 */

/**
 * Defines Environment provider capabilities.
 *
 *
 */
global class FunctionsDataSourceProvider extends DataSource.Provider {
    
    global FunctionsDataSourceProvider() {
    }

    override global List<DataSource.AuthenticationCapability> getAuthenticationCapabilities() {
        List<DataSource.AuthenticationCapability> capabilities = new List<DataSource.AuthenticationCapability>();
        capabilities.add(DataSource.AuthenticationCapability.ANONYMOUS);
        System.debug(capabilities);
        return capabilities;
    }

    override global List<DataSource.Capability> getCapabilities() {
        List<DataSource.Capability> capabilities = new List<DataSource.Capability>();
        capabilities.add(DataSource.Capability.ROW_QUERY);
        System.debug(capabilities);        
        return capabilities;
    }

    override global DataSource.Connection getConnection(DataSource.ConnectionParams connectionParams) {
        return new FunctionsDataSourceConnection(connectionParams);
    }    
}