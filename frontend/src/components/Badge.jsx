function Badge({ children, variant = 'default', size = 'medium', pulse = false }) {
  const variants = {
    default: 'badge-default',
    primary: 'badge-primary',
    success: 'badge-success',
    warning: 'badge-warning',
    error: 'badge-error',
    info: 'badge-info',
    legendary: 'badge-legendary',
    epic: 'badge-epic',
    rare: 'badge-rare',
    uncommon: 'badge-uncommon',
    common: 'badge-common'
  };

  const sizes = {
    small: 'badge-sm',
    medium: 'badge-md',
    large: 'badge-lg'
  };

  return (
    <span className={`badge ${variants[variant]} ${sizes[size]} ${pulse ? 'badge-pulse' : ''}`}>
      {children}
    </span>
  );
}

export function RarityBadge({ rarity }) {
  const rarityConfig = {
    legendary: { label: 'Legendary', variant: 'legendary' },
    epic: { label: 'Epic', variant: 'epic' },
    rare: { label: 'Rare', variant: 'rare' },
    uncommon: { label: 'Uncommon', variant: 'uncommon' },
    common: { label: 'Common', variant: 'common' }
  };

  const config = rarityConfig[rarity.toLowerCase()] || rarityConfig.common;
  
  return (
    <Badge variant={config.variant} size="small">
      {config.label}
    </Badge>
  );
}

export function StatusBadge({ status }) {
  const statusConfig = {
    minted: { label: 'Minted', variant: 'success' },
    pending: { label: 'Pending', variant: 'warning', pulse: true },
    available: { label: 'Available', variant: 'info' },
    sold: { label: 'Sold', variant: 'error' }
  };

  const config = statusConfig[status.toLowerCase()] || { label: status, variant: 'default' };
  
  return (
    <Badge variant={config.variant} pulse={config.pulse}>
      {config.label}
    </Badge>
  );
}

export default Badge;
