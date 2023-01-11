const { expect } = require('chai')
const { ethers } = require('hardhat');

describe('Account contract', () => {
    let acc1, acc2, accountsContract;

    beforeEach(async() => {
        [acc1, acc2] = await ethers.getSigners();
        const AccountsContract = await ethers.getContractFactory("Account", acc1);
        accountsContract = await AccountsContract.deploy();
        await accountsContract.deployed();
    })

    it("Correct faceit owner address", async() => {
        const owner = await accountsContract.faceitOwner()
        expect(acc1.address).to.be.eq(owner);
    })

    it("should correctly work with getPlayer with no player created yet", async() => {
        expect(accountsContract.connect(acc2).getPlayer()).to.be.reverted;
    })

    it("should correctly work with getBalance with no player created yet", async() => {
        expect(accountsContract.connect(acc2).getBalance()).to.be.reverted;
    })

    it("Correct contract address", async() => {
        expect(accountsContract.address).to.be.properAddress;
    });

    it("by default 0 ether at contract balance", async() => {
        const balance = await accountsContract.connect(acc2).contractCurrentBalance();
        expect(balance).to.be.eq(0);
    })

    it("shoud be impossible to participate without created account", async() => {
        expect(accountsContract.connect(acc2).participate()).to.be.reverted;
    })

    it("should allow to send money", async() => {
        const tx = await acc2.sendTransaction({ to: accountsContract.address, value: 100 })
        await expect(() => tx)
            .to.changeEtherBalances([acc2, accountsContract], [-100, 100]);
    })

    it("should be impossible to claim eth without created account", async() => {
        expect(accountsContract.connect(acc2).balanceAccrual(2000)).to.be.reverted;
    })


    describe("create player account", () => {


        beforeEach(async() => {
            const tx = await accountsContract.connect(acc2).createPlayerAccount(
                "vasyan",
                1839
            );
            await tx.wait();
        })

        it("creates player acoount correctly", async() => {
            let playerDto = await accountsContract.connect(acc2).getPlayer();
            expect(playerDto.nickname).to.be.eq("vasyan");
            expect(playerDto.balance).to.be.eq(0);
            expect(playerDto.rating).to.be.eq(1839);
            expect(playerDto.created).to.be.eq(true);
        })

        it("should be impossibe to create account if one already exist", async() => {
            expect(accountsContract.connect(acc2).createPlayerAccount(
                "vasyan",
                1839
            )).to.be.reverted
        })

        it("correctly make a participant from player", async() => {
            const tx = await accountsContract.connect(acc2).participate({ value: ethers.utils.parseEther("0.00375") });
            let playerDto = await accountsContract.connect(acc2).getPlayer();
            expect(playerDto.participant).to.be.eq(true);
        })

        it("not owner can't use withdraw currency from contract", async() => {
            expect(accountsContract.connect(acc2).withdraw()).to.be.reverted;
        })

        it("owner can use withdraw currency from contract", async() => {
            await accountsContract.connect(acc1).withdraw()
            const balance = await accountsContract.connect(acc2).contractCurrentBalance();
            expect(balance).to.be.eq(0);
        })

        it("player can view what that claim during week", async() => {
            const playerBalance = await accountsContract.connect(acc2).getBalance();
            expect(playerBalance).to.be.eq(0);
        })

        it("should be impossible to claim point without participation", async() => {
            expect(accountsContract.connect(acc2).balanceAccrual(2000)).to.be.reverted;
        })

        it("should be possible to send funds from created user to contract", async() => {
            const val = ethers.utils.parseEther("0.00375");
            const tx = await accountsContract.connect(acc2).participate({ value: val });
            await expect(() => tx)
                .to.changeEtherBalances([acc2, accountsContract], [-val, val]);
            await tx.wait();
        })

        describe("participating in faceit event after 1 week", async() => {
            beforeEach(async() => {
                const tx = await accountsContract.connect(acc2).participate({ value: ethers.utils.parseEther("0.00375") });
                await tx.wait();

                const ownerTx = await accountsContract.connect(acc1).correctClaimTime(acc2.address);
                await ownerTx.wait();
            })

            it("claim eth should transfer eth from contract to player", async() => {
                const newRating = 1849;

                const tx = await accountsContract.connect(acc2).balanceAccrual(newRating);
                await expect(() => tx)
                    .to.changeEtherBalances([accountsContract, acc2], [-10, 10]);
                const timestamp = (await ethers.provider.getBlock(tx.blockNumber)).timestamp
                const playerBalance = await accountsContract.connect(acc2).getBalance()
                await expect(tx)
                    .to.emit(accountsContract, "balanceChanged")
                    .withArgs(acc2.address, playerBalance, 10, timestamp);

            })

            it("should correctly transfer with 0 gain claim", async() => {
                const newRating = 1000;
                expect(accountsContract.connect(acc2).balanceAccrual(newRating)).to.be.revertedWith("zero gain");

            })

            it("should correct work with not enough currency on contract", async() => {
                const newRating = 5000;
                expect(accountsContract.connect(acc2).balanceAccrual(newRating)).to.be.revertedWith("not enough currency on contract");
            })

        })

        describe("participating in faceit event before 1 week", async() => {
            beforeEach(async() => {
                const val = ethers.utils.parseEther("0.00375");
                const tx = await accountsContract.connect(acc2).participate({ value: val });
                await tx.wait();
            })

            it("claim eth should corretly transfer eth from contract to player", async() => {
                const newRating = 1849;

                expect(accountsContract.connect(acc2).balanceAccrual(newRating)).to.be.revertedWith("it hasn't been a week yet");


            })

            it("should be 1 sec after account creation (can't claim)", async() => {
                const timestamp = await accountsContract.connect(acc2).getTimeForNextClaim();
                expect(timestamp.toNumber()).to.be.lessThanOrEqual(1);

            })

        })

    })
})