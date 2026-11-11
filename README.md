# SampleChain

1. `npm install`
2. `cp .env.example .env` y completá `PRIVATE_KEY` (wallet con AVAX de Fuji) y las wallets `COLLECTOR`, `TRANSPORTER`, `LAB`.
3. `npm run deploy:fuji` y copiá `CONTRACT_ADDRESS` al `.env`.
4. `npm start` y abrí http://localhost:3000
5. Demo: en MetaMask cambiá de cuenta (geólogo, transportista, laboratorio) y recargá la conexión en cada paso.

Flujo del contrato: crear → TRANSPORTED → RECEIVED → PREPARED → ANALYZED → certificar. Saltarse un paso revierte la transacción.
Auditoría pública: `/verify/LIT-001` (sin wallet).
