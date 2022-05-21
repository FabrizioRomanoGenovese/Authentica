# Motivation

Lately I have spoken with many non-digital artists that
were interested in using NFTs to autenticate their work. 

The idea is simple: you sell an artwork and transfer an NFT to the owner testifying originality. The NFT 'authentica' will have to be transferred along with the artwork from one owner to the next.

The problem with this approach is that many traditional art collectors do not own a crypto wallet, and as such it is impossible to transfer an NFT to them.

## Authentica
`Authentica` is a very simple contract that implements a commit-reveal scheme. It is designed to work in tandem with NFT contracts satisfying the ERC1155 standard. It works like this:

1. Artist creates a work and mints an NFT representing it;
2. Artist deploys an `Authentica` contract pointing to the NFT contract being used;
3. Artist sets up one or more 'custodian' wallets and transfers the relevant NFTs there
4. Custodian wallet must set `isApprovedForAll` to `true` for the `Authentica` contract. This gives `Authentica` the possibility to transfer tokens from the custodian wallet.
5. Artist publishes a `secret` on `Authentica` corresponding to the `tokenId`, together with an `allowance` saying how many tokens of that id `secret` is allowed to withdraw.
6. Artist prints the secret, e.g. on a QR code, and attaches it to the physical artwork during sale.

--- 
...When collector finally sets up a wallet,
1. Collector publishes a `commitment` on `Authentica`. This is nothing more than the hash of collector address XORed with `secret`.
2. When `commitment` is mined, collector reveals `secret`. `Authentica` verifies that secret and `commitment` check out and transfers the NFT from the custodian wallet to the collector wallet.

The reason why we use a commit-reveal scheme is because [Etheremum is a Dark Forest](https://www.paradigm.xyz/2020/08/ethereum-is-a-dark-forest). A simpler solution would most certainly mean that collector's secret would be sniped before reaching a block.

## Usage
This is your standard Foundry project. Refer to [Foundry Github Page](https://github.com/foundry-rs/foundry) for more info.

The way `Authentica` should be used is by deploying it as a separate contract. An example of this is provided in the `src/examples/` folder: We deploy a NFT ERC1155 contract first, and then we deploy a contract inheriting from Authentica pointing to it.

## Risks
- If collector deploys `secret` before `commitment` there's nothing we can do to avoid mempool sniping.
- `allowance` in Authentica does not follow the NFT allowance. That is, you may mint 3 NFTs with id 0 and give an allowance of 500 for a secret pointing to id 0.
Trying to spend the remaining allowance will revert unless tokens are returned to the custodian wallet. Long story short: It's up to the artist to set up `allowance` in a meaningful way.
- If a collector used `secret` and sells the artwork to a new collector lacking a wallet, a new `secret` can be provided but it requires the collaboration of whoever administers the `Authentica` contract - most likely the artist. This entails transferring the NFT back to a custodian wallet and pushing a new secret.

    Alternatively, the collector may set up a new `Authentica` contract pointing to the same NFT contract, but this seems like an overkill application unless collector owns an Art gallery or something along those lines.

## TODOs

I am slowly writing the tests, but any help is appreciated.

I don't expect artists to be procient programmers, so a mock web3 interface with a command center to manage minting, authorizations etc would also be a good idea.