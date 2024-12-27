import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new profile",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'create-profile', [
                types.ascii("Alice"),
                types.ascii("Fun loving person"),
                types.uint(25),
                types.list([types.ascii("music"), types.ascii("travel")])
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Verify profile creation
        let profileBlock = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'get-profile', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        const profile = profileBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(profile.name, "Alice");
    }
});

Clarinet.test({
    name: "Can send and manage connection requests",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'send-connection-request', [
                types.principal(wallet2.address)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Can schedule and review virtual dates",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // Schedule date
        let scheduleBlock = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'schedule-date', [
                types.principal(wallet2.address),
                types.uint(1234567),
                types.ascii("Virtual Beach")
            ], wallet1.address)
        ]);
        
        const dateId = scheduleBlock.receipts[0].result.expectOk();
        
        // Submit review
        let reviewBlock = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'submit-review', [
                dateId,
                types.principal(wallet2.address),
                types.uint(5),
                types.ascii("Great date!")
            ], wallet1.address)
        ]);
        
        reviewBlock.receipts[0].result.expectOk();
    }
});