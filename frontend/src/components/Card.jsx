function Card({ children, className = '', variant = 'default', hover = true, onClick }) {
  const variants = {
    default: 'card-default',
    highlighted: 'card-highlighted',
    glass: 'card-glass',
    gradient: 'card-gradient'
  };

  return (
    <div 
      className={`card ${variants[variant]} ${hover ? 'card-hover' : ''} ${className}`}
      onClick={onClick}
      onKeyDown={(event) => {
        if (!onClick) return;
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          onClick(event);
        }
      }}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {children}
    </div>
  );
}

export function CardHeader({ children, className = '' }) {
  return <div className={`card-header ${className}`}>{children}</div>;
}

export function CardBody({ children, className = '' }) {
  return <div className={`card-body ${className}`}>{children}</div>;
}

export function CardFooter({ children, className = '' }) {
  return <div className={`card-footer ${className}`}>{children}</div>;
}

export function CardImage({ src, alt, className = '' }) {
  return (
    <div className={`card-image ${className}`}>
      <img src={src} alt={alt} loading="lazy" />
    </div>
  );
}

export default Card;
