import React, { useState } from "react";
import { ITokenSetInfo } from "../Pages/Home/Home";
import { erc20ABI, useAccount, erc721ABI } from 'wagmi';
import { readContract } from 'wagmi/actions';
import contracts from '../config/contracts.json';

const TokenBalance = ({tokenContract, setTokenContract, erc20TokenContract, setErc20TokenContract}: ITokenSetInfo) => {

  const { isConnected, address } = useAccount();

  const [nftTokenBalance, setNftTokenBalance] = useState(0);
  const [erc20TokenBalance, setErc20TokenBalance] = useState(0);

  const fetchNftTokenBalance = async (tokenAddress: any, index: number) => {

    if (address === undefined || !isConnected) {
      alert("Please connect your wallet");
      return;
    }

    if (tokenAddress === undefined || tokenAddress === '') {
      console.log("Please select a token");
      return;
    }

    const balance = await readContract({
      address: tokenAddress,
      abi: erc721ABI,
      functionName: 'balanceOf',
      args: [address],
    });

    setNftTokenBalance(Number(balance) as unknown as number);
  }

  const fetchErc20TokenBalance = async (tokenAddress: any, index: number) => {
      
      if (address === undefined || !isConnected) {
        alert("Please connect your wallet");
        return;
      }

      if (tokenAddress === undefined || tokenAddress === '') {
        console.log("Please select a token");
        return;
      }
  
      const balance = await readContract({
        address: tokenAddress,
        abi: erc20ABI,
        functionName: 'balanceOf',
        args: [address],
      });
  
      setErc20TokenBalance(Number(balance) as unknown as number);
  }

  if (!tokenContract || tokenContract === '') setTokenContract(contracts.erc721[0].address);
  if (!erc20TokenContract || erc20TokenContract === '') setErc20TokenContract(contracts.erc20[0].address);

  fetchNftTokenBalance(tokenContract, 0);
  fetchErc20TokenBalance(erc20TokenContract, 0);

  return(
    <div>
      <div className="mb-3">
        <label className="form-label">NFT Token Balance: <span className='text-primary'>{nftTokenBalance}</span></label>
        <select className="form-select" aria-label="Select your ERC271 token" value={tokenContract} onChange={id => {

            console.log("eslecte nft", id, id.target.value);
            const index = id.target[id.target.selectedIndex].getAttribute('data-idx');
          console.log("eslecte nft", id, id.target.value, index);
            setTokenContract(id.target.value);
            fetchNftTokenBalance(id.target.value, Number(index));
        }}>
            {contracts.erc721.map((contract, idx) => <option key={idx} value={contract.address} data-idx={idx}> {`${contract.name} (${contract.symbol})`}</option>)}

        </select>
      </div>

      <div className="mb-3">
        <label className="form-label">ERC 20 Token Balance: <span className='text-primary'>{erc20TokenBalance}</span></label>
        <select className="form-select" aria-label="Select your ERC 20 token" onChange={id => {
          
          const index = id.target[id.target.selectedIndex].getAttribute('data-idx');
          console.log("eslecte erc20", id, id.target.value, index);
          setErc20TokenContract(id.target.value)
          fetchErc20TokenBalance(id.target.value, Number(index));
          }} value={erc20TokenContract}>
            {contracts.erc20.map((contract, idx) => <option key={idx} value={contract.address} data-idx={idx}> {`${contract.name} (${contract.symbol})`}</option>)}

        </select>
      </div>
    </div>
  )
}

export default TokenBalance;