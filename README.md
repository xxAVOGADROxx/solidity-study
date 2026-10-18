# solidity-study

Plan de 2 semanas para pasar de cero a escribir, probar y desplegar contratos en Solidity con
[Foundry](https://getfoundry.sh). Pensado para alguien que viene de Cardano (Plutus/Aiken):
ver [docs/paralelos-cardano.md](docs/paralelos-cardano.md).

## Qué hay en el repo

| Archivo | Qué enseña |
|---|---|
| `src/Counter.sol` | El ejemplo por defecto de Foundry: estado, funciones, primer test |
| `src/StudyToken.sol` | ERC-20 escrito **a mano**: mappings, eventos, errores, allowance, `unchecked`, `immutable` |
| `src/OZToken.sol` | El mismo token hecho "como en producción": herencia de OpenZeppelin + `permit` (EIP-2612) |
| `src/StudyNFT.sol` | ERC-721 con mint pagado, supply máximo, `payable`, retiro de fondos |
| `src/Vault.sol` | Bóveda **vulnerable a reentrancy** y su versión segura (CEI + `ReentrancyGuard`) |
| `test/*.t.sol` | Tests unitarios, de fuzzing, de invariantes y un ataque de reentrancy real |
| `script/DeployStudyToken.s.sol` | Script de despliegue (anvil local o Sepolia) |

## Comandos

```bash
forge build                 # compilar
forge test                  # todos los tests
forge test -vvvv            # con trazas de cada llamada (ideal para entender un fallo)
forge test --mt test_Transfer   # un solo test por nombre
forge test --gas-report     # costo de gas por función
forge snapshot              # guarda el gas de cada test en .gas-snapshot (compara optimizaciones)
forge coverage              # cobertura
forge fmt                   # formatear
anvil                       # nodo Ethereum local (como un devnet de Cardano)
cast --help                 # CLI para leer/escribir en la cadena
chisel                      # REPL de Solidity
```

## Plan de 2 semanas

Cada día: **leer** (1–2 h) → **hacer** (1–2 h). Los ejercicios se hacen en este repo, con tests.

### Semana 1: lenguaje, tokens y testing

**Día 1: Setup y primer contrato**
- Leer: [Solidity — Introduction to Smart Contracts](https://docs.soliditylang.org/en/latest/introduction-to-smart-contracts.html); [Foundry Book — Getting Started](https://getfoundry.sh/introduction/getting-started) y "Writing Tests".
- Curso: [Cyfrin Updraft — Solidity Smart Contract Development](https://updraft.cyfrin.io/courses/solidity), sección 1.
- Hacer: lee `Counter.sol` y su test. Agrega `decrement()` que revierta en 0 con un custom error, y su test.

**Día 2: Tipos, ubicación de datos y estado**
- Leer: docs "Types", "Data location" (storage / memory / calldata); [Solidity by Example](https://solidity-by-example.org): Primitive Data Types, Variables, Mapping, Array, Struct, Enum.
- Hacer: contrato `TodoList` con `struct Todo`, un `mapping(address => Todo[])` y funciones para crear/completar. Test de cada función.

**Día 3: Funciones, visibilidad, modifiers, ETH**
- Leer: docs "Functions", "Function Modifiers", "Receive Ether Function"; SbE: Function, Visibility, Modifier, Events, Error, Payable, Sending Ether, Fallback.
- Hacer: `PiggyBank`: cualquiera deposita ETH, solo el dueño retira y solo después de una fecha (`block.timestamp`). Usa `vm.warp` en el test para mover el tiempo.

**Día 4: ERC-20 desde cero**
- Leer: [EIP-20](https://eips.ethereum.org/EIPS/eip-20) completo (es corto). Luego `src/StudyToken.sol` línea por línea.
- Hacer: agrega `burn(uint256)` y `burnFrom(address,uint256)` a `StudyToken`, con tests. Compara con `OZToken.sol` y lee el código de [ERC20.sol de OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol).

**Día 5: Testing serio (tu fuerte viniendo de QuickCheck)**
- Leer: Foundry Book "Cheatcodes" (`prank`, `deal`, `warp`, `expectRevert`, `expectEmit`), "Fuzz Testing", "Invariant Testing".
- Hacer: estudia `test/StudyToken.t.sol` (unit + fuzz + invariante con handler). Agrega al handler `approve` y `transferFrom`, y un invariante nuevo: ninguna cuenta tiene más que `totalSupply`.

**Día 6: ERC-721 (NFTs)**
- Leer: [EIP-721](https://eips.ethereum.org/EIPS/eip-721); [OpenZeppelin — ERC-721 guide](https://docs.openzeppelin.com/contracts/5.x/erc721); `src/StudyNFT.sol`.
- Hacer: límite de 3 NFTs por wallet y una allowlist con `mapping(address => bool)`. Tests de los casos límite.

**Día 7: Cadena local con anvil + cast**
- Leer: Foundry Book "Anvil", "Cast", "Scripting" y "Key management" (`cast wallet import`).
- Hacer: corre `anvil`, importa una de sus cuentas de prueba con `cast wallet import`, despliega con el script, y con `cast call` / `cast send` lee el balance y transfiere tokens.

### Semana 2: seguridad, gas y ecosistema

**Día 8: Reentrancy y Checks-Effects-Interactions**
- Leer: `src/Vault.sol` + `test/Vault.t.sol` (corre `forge test --mt Reentrancy -vvvv` y sigue la traza); [Solidity — Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html).
- Hacer: [Ethernaut](https://ethernaut.openzeppelin.com) niveles 1–4 (Fallback, Fallout, Coin Flip, Telephone) y el de Re-entrancy. Escribe cada exploit como test de Foundry.

**Día 9: Control de acceso, `delegatecall` y proxies**
- Leer: [OpenZeppelin — Access Control](https://docs.openzeppelin.com/contracts/5.x/access-control); [Proxy Upgrade Pattern](https://docs.openzeppelin.com/upgrades-plugins/proxies); SbE: Delegatecall, Upgradeable Proxy.
- Hacer: Ethernaut Delegation, Force y Vault. Explica en un comentario por qué `tx.origin` no sirve para autenticación.

**Día 10: Gas**
- Leer: docs "Layout of State Variables in Storage"; [evm.codes](https://www.evm.codes) (costo de `SLOAD`/`SSTORE`); SbE: Gas Golf.
- Hacer: `forge snapshot`, luego optimiza `TodoList` o `StudyNFT` (empaquetar variables, `immutable`/`constant`, custom errors, `calldata`, `unchecked`) y compara con `forge snapshot --diff`.

**Día 11: Escrow (el "validator" de Ethereum)**
- Leer: [EIP-2612 (permit)](https://eips.ethereum.org/EIPS/eip-2612); [OpenZeppelin SafeERC20](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20#SafeERC20).
- Hacer: `Escrow`: comprador deposita un ERC-20, un árbitro libera al vendedor o devuelve al comprador, y hay reembolso automático tras un deadline. Fuzz + invariante: el contrato nunca debe más de lo que tiene.

**Día 12: Oráculos y DeFi**
- Leer: [Chainlink Data Feeds](https://docs.chain.link/data-feeds) y [Pyth (pull oracle)](https://docs.pyth.network/price-feeds); [ERC-4626 (vaults)](https://eips.ethereum.org/EIPS/eip-4626).
- Hacer: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz) reto 1 (Unstoppable). Lee la solución solo después de intentarlo.

**Día 13: Testnet**
- Leer: Foundry Book "Deploying" y "Verifying". Consigue ETH de Sepolia en un faucet y un RPC (Alchemy/Infura, plan gratis).
- Hacer: despliega `StudyToken` en Sepolia con `--account` (keystore cifrado, **nunca** una private key en `.env` ni en git) y verifícalo en Etherscan con `--verify`.

**Día 14: Proyecto final**
- Hacer: un contrato propio (staking simple, subasta o tu Escrow mejorado) con unit + fuzz + invariantes, script de deploy y un README que explique sus riesgos. Esto es lo que muestras en una entrevista.

## Documentación de referencia

- [Solidity docs](https://docs.soliditylang.org): la referencia del lenguaje.
- [Solidity by Example](https://solidity-by-example.org): un concepto por página.
- [Foundry Book](https://getfoundry.sh): forge, cast, anvil y chisel.
- [Cyfrin Updraft](https://updraft.cyfrin.io): curso gratis completo (Solidity, Foundry, seguridad y auditoría).
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/5.x): implementaciones auditadas de los ERC.
- [EIPs](https://eips.ethereum.org): los estándares originales (20, 721, 1155, 2612, 4626).
- [evm.codes](https://www.evm.codes): opcodes y costos de gas.
- [Ethernaut](https://ethernaut.openzeppelin.com) y [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz): retos de seguridad.
- [Solodit](https://solodit.cyfrin.io): base de datos de hallazgos reales de auditorías.
