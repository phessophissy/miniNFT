function ProgressBar({ progress, minted, total }) {
  return (
    <div className="progress-container">
      <div className="progress-header">
        <span className="progress-label">Minting Progress</span>
        <span className="progress-count">{minted} / {total}</span>
      </div>
      <div className="progress-bar ring-growth">
        <div
          className="progress-fill"
          style={{ width: `${progress}%` }}
        >
          {progress >= 10 && (
            <span className="progress-inner-text">{progress.toFixed(1)}%</span>
          )}
        </div>
      </div>
      <div className="progress-text">
        {progress < 100
          ? `${(100 - progress).toFixed(1)}% remaining`
          : '🎉 Sold Out!'}
      </div>
    </div>
  );
}

export default ProgressBar;
