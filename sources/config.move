/// Module handles global stake pool configuration:
///   * allows to enable "global emergency state", which disables all the operations on the `StakePool` instances,
///     except for the `emergency_unstake()`.
///   * allows to specify custom `emergency_admin` account.
module staking::config {

    // Errors.

    use sui::tx_context::{TxContext, sender};
    use sui::transfer;
    use sui::object::UID;
    use sui::object;

    /// Doesn't have enough permissions: not a current admin account.
    const ERR_NO_PERMISSIONS: u64 = 200;

    /// Global config is not initialized, call `initialize()` first.
    const ERR_NOT_INITIALIZED: u64 = 201;

    /// Operation is not accessible as "global emergency state" is enabled.
    const ERR_GLOBAL_EMERGENCY: u64 = 202;

    ///Witness
    struct CONFIG has drop {}

    // Resources.

    /// Global config: contains emergency lock and admin address.
    struct GlobalConfig has key, store {
        id: UID,
        stake_admin_address: address,
        treasury_admin_address: address,
        global_emergency_locked: bool,
    }

    // Functions.

    /// Initializes global configuration.
    ///     * `emergency_admin` - initial emergency admin account.
    ///     * `treasury_admin` - initial treasury admin address.
    fun init(_witness: CONFIG, ctx: &mut TxContext){
        assert!(sender(ctx) == @stake_admin, ERR_NO_PERMISSIONS);
        transfer::share_object(GlobalConfig {
            id: object::new(ctx),
            stake_admin_address: @stake_admin,
            treasury_admin_address: @treasury_admin,
            global_emergency_locked: false,
        })
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CONFIG {}, ctx)
    }

    /// Sets `emergency_admin` account.
    /// Should be signed with current `emergency_admin` account.
    ///     * `stake_admin` - current emergency admin account.
    ///     * `new_address` - new emergency admin address.
    public fun set_stake_admin_address(global_config: &mut GlobalConfig, new_address: address, ctx: &mut TxContext) {
        assert!(sender(ctx) == global_config.stake_admin_address, ERR_NO_PERMISSIONS);
        global_config.stake_admin_address = new_address;
    }

    /// Gets current address of `emergency_admin` account.
    /// Returns address of emergency admin account.
    public fun get_stake_admin_address(global_config: &GlobalConfig): address {
        global_config.stake_admin_address
    }

    /// Sets `treasury_admin` account.
    /// Should be signed with current `treasury_admin` account.
    ///     * `global_config` - current treasury admin account.
    ///     * `new_address` - new treasury admin address.
    ///     * ctx: current treasury_admin
    public fun set_treasury_admin_address(global_config: &mut GlobalConfig, new_address: address, ctx: &mut TxContext) {
        assert!(sender(ctx) == global_config.treasury_admin_address, ERR_NO_PERMISSIONS);
        global_config.treasury_admin_address = new_address;
    }

    /// Gets current address of `treasury admin` account.
    /// Returns address of treasury admin.
    public fun get_treasury_admin_address(global_config: &GlobalConfig): address {
        global_config.treasury_admin_address
    }

    /// Enables "global emergency state". All the pools' operations are disabled except for `emergency_unstake()`.
    /// This state cannot be disabled, use with caution.
    ///     * `emergency_admin` - current emergency admin account.
    public fun enable_global_emergency(global_config: &mut GlobalConfig, ctx: &mut TxContext) {
        assert!(sender(ctx) == global_config.stake_admin_address, ERR_NO_PERMISSIONS);
        assert!(!global_config.global_emergency_locked, ERR_GLOBAL_EMERGENCY);
        global_config.global_emergency_locked = true;
    }

    /// Checks whether global "emergency state" is enabled.
    /// Returns true if emergency enabled.
    public fun is_global_emergency(global_config: &GlobalConfig): bool {
        global_config.global_emergency_locked
    }
}
