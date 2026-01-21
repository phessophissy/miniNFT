import { CONTRACT_ADDRESS } from '../contract';
import { CopyButton, Tooltip } from './index';

function Footer() {
  return (
    <footer className="footer">
      <div className="footer-content">
        <div className="footer-brand">
          <span className="logo-icon">💎</span>
          <span>MiniNFT</span>
        </div>
        <p className="footer-tagline">505 unique NFTs on Base Chain</p>
        <div className="footer-links">
          <a 
            href={`https://basescan.org/address/${CONTRACT_ADDRESS}`}
            target="_blank"
            rel="noopener noreferrer"
          >
            📄 Contract
          </a>
          <Tooltip content={CONTRACT_ADDRESS} position="top">
            <span className="footer-contract">
              {CONTRACT_ADDRESS.slice(0, 6)}...{CONTRACT_ADDRESS.slice(-4)}
            </span>
          </Tooltip>
          <CopyButton text={CONTRACT_ADDRESS} label="Copy Address" copiedLabel="Copied" />
          <a 
            href="https://opensea.io/collection/mininft"
            target="_blank"
            rel="noopener noreferrer"
          >
            🖼️ OpenSea
          </a>
          <a 
            href="https://github.com/AdekunleBamz/miniNFT"
            target="_blank"
            rel="noopener noreferrer"
          >
            💻 GitHub
          </a>
        </div>
        <p className="footer-copy">© 2026 MiniNFT | Built on Base</p>
      </div>
    </footer>
  );
}

export default Footer;
