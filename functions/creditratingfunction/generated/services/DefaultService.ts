/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { account } from '../models/account';
import type { creditRating } from '../models/creditRating';

import type { CancelablePromise } from '../core/CancelablePromise';
import { OpenAPI } from '../core/OpenAPI';
import { request as __request } from '../core/request';

export class DefaultService {

    /**
     * Evaluates credit rating and decides what payment terms to offer.
     * @param requestBody Specifies input parameters to calculate payment term
     * @returns creditRating Credit rating response
     * @throws ApiError
     */
    public static post(
        requestBody: account,
    ): CancelablePromise<creditRating> {
        return __request(OpenAPI, {
            method: 'POST',
            url: '/',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                405: `Invalid input`,
            },
        });
    }

}
