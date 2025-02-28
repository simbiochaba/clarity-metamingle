import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensures age validation in profile creation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'create-profile', [
                types.ascii("Alice"),
                types.ascii("Fun loving person"),
                types.uint(17), // Under minimum age
                types.list([types.ascii("music"), types.ascii("travel")])
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr(403); // Invalid age error
    }
});

[... rest of the original tests with additional test cases ...]
