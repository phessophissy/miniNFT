import { useState, useEffect } from 'react';
import { Header, Stats, MintCard, Gallery, Features, Footer } from './components';
import { useNFTContract } from './hooks';
import { MAX_SUPPLY } from './contract';

function App() {
  const {
    address,
    isConnected,
    minted,
    remaining,
    progress,
    userBalance,
    hash,
    writeContract,
    isPending,
    isConfirming,
    isSuccess,
    writeError,
    refetchAll,
  } = useNFTContract();

  const [recentMints, setRecentMints] = useState([]);

  // Refetch data after successful mint
  useEffect(() => {
    if (isSuccess) {
      refetchAll();
      setRecentMints(prev => [{
        txHash: hash,
        timestamp: new Date().toLocaleTimeString(),
      }, ...prev.slice(0, 4)]);
    }
  }, [isSuccess, hash]);

  return (
    <div className="app">
      {/* Background effects */}
      <div className="bg-effects forest-floor">
        <div className="gradient-orb orb-1"></div>
        <div className="gradient-orb orb-2"></div>
        <div className="gradient-orb orb-3"></div>
        <div className="wood-grain-animated" style={{ position: 'absolute', inset: 0, opacity: 0.15 }}></div>
        <div className="smoke-rise" style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}></div>
      </div>

      <Header />

      <main className="main">
        {/* Hero section */}
        <div className="hero">
          <h1 className="title">
            Mint Your <span className="gradient-text">MiniNFT</span>
          </h1>
          <p className="subtitle">
            A collection of 1005 unique NFTs on Base Chain
          </p>
        </div>

        {/* Stats */}
        <Stats
          minted={minted}
          remaining={remaining}
          userBalance={userBalance}
          isConnected={isConnected}
        />

        {/* Progress bar */}
        <div className="progress-container">
          <div className="progress-bar">
            <div className="progress-fill" style={{ width: `${progress}%` }}></div>
          </div>
          <div className="progress-text">{progress.toFixed(1)}% minted</div>
        </div>

        {/* Mint card */}
        <MintCard
          isConnected={isConnected}
          remaining={remaining}
          writeContract={writeContract}
          isPending={isPending}
          isConfirming={isConfirming}
          isSuccess={isSuccess}
          hash={hash}
          writeError={writeError}
        />

        {/* Recent mints */}
        {recentMints.length > 0 && (
          <div className="recent-mints">
            <h3>Your Recent Mints</h3>
            <div className="recent-list">
              {recentMints.map((mint, index) => (
                <div key={index} className="recent-item">
                  <span>{mint.timestamp}</span>
                  <a
                    href={`https://basescan.org/tx/${mint.txHash}`}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    View TX →
                  </a>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* User's Gallery */}
        <Gallery address={address} userBalance={userBalance} />

        {/* Features */}
        <Features />
      </main>

      <Footer />
    </div>
  );
}

export default App;
