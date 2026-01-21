import { useState } from 'react';

function CopyButton({ text, label = 'Copy', copiedLabel = 'Copied!', className = '' }) {
  const [isCopied, setIsCopied] = useState(false);

  const handleCopy = async () => {
    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text);
      } else {
        const temp = document.createElement('textarea');
        temp.value = text;
        document.body.appendChild(temp);
        temp.select();
        document.execCommand('copy');
        document.body.removeChild(temp);
      }
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 1500);
    } catch {
      setIsCopied(false);
    }
  };

  return (
    <button className={`copy-btn ${className}`} onClick={handleCopy} type="button">
      {isCopied ? copiedLabel : label}
    </button>
  );
}

export default CopyButton;
