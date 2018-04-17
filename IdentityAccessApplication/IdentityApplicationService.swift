//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import IdentityAccessDomainModel

open class IdentityApplicationService {

    private var secureStore: SecureStore { return DomainRegistry.secureStore }
    private var keyValueStore: KeyValueStore { return DomainRegistry.keyValueStore }
    private var encryptionService: EncryptionServiceProtocol { return DomainRegistry.encryptionService }

    public init() {}

    open var isRecoverySet: Bool {
        return keyValueStore.bool(for: UserDefaultsKey.isRecoveryOptionSet.rawValue) ?? false
    }

    open func getEOA() throws -> ExternallyOwnedAccount? {
        guard let mnemonic = try secureStore.mnemonic() else { return nil }
        let account = EthereumAccountFactory(service: encryptionService).account(from: mnemonic)
        return account as? ExternallyOwnedAccount
    }

    open func getOrCreateEOA() throws -> ExternallyOwnedAccount {
        if let eoa = try getEOA() {
            return eoa
        }
        let account = EthereumAccountFactory(service: encryptionService).generateAccount()
        try secureStore.saveMnemonic(account.mnemonic)
        try secureStore.savePrivateKey(account.privateKey)
        return account as! ExternallyOwnedAccount
    }

}
