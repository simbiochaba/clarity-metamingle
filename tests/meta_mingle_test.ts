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
    name: "Can create and send virtual gifts",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // Create gift
        let createGiftBlock = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'create-gift', [
                types.ascii("Virtual Rose"),
                types.ascii("A beautiful virtual rose"),
                types.uint(50)
            ], wallet1.address)
        ]);
        
        createGiftBlock.receipts[0].result.expectOk();
        
        // Send gift
        let sendGiftBlock = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'send-gift', [
                types.uint(0),
                types.principal(wallet2.address)
            ], wallet1.address)
        ]);
        
        sendGiftBlock.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Can generate and retrieve matches",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create profile first
        let profileBlock = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'create-profile', [
                types.ascii("Alice"),
                types.ascii("Fun loving person"),
                types.uint(25),
                types.list([types.ascii("music"), types.ascii("travel")])
            ], wallet1.address)
        ]);
        
        profileBlock.receipts[0].result.expectOk();
        
        // Generate matches
        let matchBlock = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'generate-matches', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        matchBlock.receipts[0].result.expectOk();
        
        // Get matches
        let getMatchesBlock = chain.mineBlock([
            Tx.contractCall('meta-mingle', 'get-matches', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        getMatchesBlock.receipts[0].result.expectOk();
    }
});
