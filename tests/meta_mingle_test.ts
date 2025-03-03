import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensures privacy settings work correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create profile
        let block = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'create-profile', [
                types.ascii("Alice"),
                types.ascii("Bio"),
                types.uint(25),
                types.list([types.ascii("music")])
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();

        // Update privacy
        block = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'update-privacy-level', [
                types.uint(2) // friends only
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});
