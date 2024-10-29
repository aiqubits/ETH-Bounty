//!
//! Stylus Hello World
//!
//! The following contract implements the Counter example from Foundry.
//!
//! ```
//! contract Counter {
//!     uint256 public number;
//!     function setNumber(uint256 newNumber) public {
//!         number = newNumber;
//!     }
//!     function increment() public {
//!         number++;
//!     }
//! }
//! ```
//!
//! The program is ABI-equivalent with Solidity, which means you can call it from both Solidity and Rust.
//! To do this, run `cargo stylus export-abi`.
//!
//! Note: this code is a template-only and has not been audited.
//!

// Allow `cargo stylus export-abi` to generate a main function.
#![cfg_attr(not(feature = "export-abi"), no_main)]
extern crate alloc;

/// Import items from the SDK. The prelude contains common traits and macros.
use stylus_sdk::{
    prelude::*,
    alloy_primitives::U256,
    storage::{StorageAddress, StorageU256},
    call::transfer_eth,
    msg,
    block,
};

// Define some persistent storage using the Solidity ABI.
// `Counter` will be the entrypoint.
#[storage]
#[entrypoint]
pub struct DutchAuction {
    seller: StorageAddress,
    starting_price: StorageU256,
    reserve_price: StorageU256,
    start_time: StorageU256,
    end_time: StorageU256,
    price_decrement: StorageU256,
}

/// Declare that `Counter` is a contract with the following external methods.
#[public]
impl DutchAuction {
    /// 创建一个荷兰拍卖
    pub fn new(&mut self, starting_price: U256, reserve_price: U256, duration: U256, price_decrement: U256) ->  Result<(), Vec<u8>> {
        let start_time = U256::from(block::timestamp());
        let end_time = start_time + duration;
        self.seller.set(msg::sender());
         self.starting_price.set(starting_price);
         self.reserve_price.set(reserve_price);
         self.start_time.set(start_time);
         self.end_time.set(end_time);
         self.price_decrement.set(price_decrement);
        Ok(())
    }

    // 获取当前拍卖得价格
    pub fn get_current_price(&self) -> U256 {
        let current_time = U256::from(block::timestamp());
        if current_time >= self.end_time.get() {
            return self.reserve_price.get();
        }
        let elapsed_time = current_time - self.start_time.get();
        let price_decrement_per_second = self.price_decrement.get() / (self.end_time.get() - self.start_time.get());
        let current_price = self.starting_price.get() - (elapsed_time * price_decrement_per_second);
        if current_price < self.reserve_price.get() {
            self.reserve_price.get()
        } else {
            current_price
        }
    }

    // 购买拍卖品
    pub fn buy(&mut self) -> Result<(), Vec<u8>> {
        let current_price = self.get_current_price();
        let amount_sent = msg::value();
        assert!(amount_sent >= current_price, "Insufficient payment");
        transfer_eth(self.seller.get(), amount_sent)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use stylus_sdk::{
        prelude::*,
        msg,
        block,
        evm,
        Address,
    };
    // unimplement todo!
    #[test]
    fn test_dutch_auction() {
        let starting_price = U256::from(1000);
        let reserve_price = U256::from(500);
        let duration = U256::from(100);
        let price_decrement = U256::from(5);

        DutchAuction::new(&mut DutchAuction, starting_price, reserve_price, duration, price_decrement);

        // Test initial price
        assert_eq!(DutchAuction::get_current_price(), starting_price);

        // Fast forward time by 50 seconds
        block::set_timestamp(block::timestamp() + 50);
        let expected_price = starting_price - (U256::from(50) * price_decrement / U256::from(duration));
        assert_eq!(DutchAuction::get_current_price(), expected_price);

        // Fast forward time to end of auction
        block::set_timestamp(block::timestamp() + 50);
        assert_eq!(DutchAuction::get_current_price(), reserve_price);

        // Test buying at reserve price
        msg::set_value(reserve_price);
        DutchAuction::buy();
        // Verify funds transferred to seller
        assert_eq!(evm::balance(msg::sender()), reserve_price);
    }
}
