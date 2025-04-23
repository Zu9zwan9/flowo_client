'use client';

import React, { useEffect, useState, useRef } from 'react';
import { useTheme } from '@/components/ThemeProvider';
import { hexToRgba } from '@/utils/colors';

interface AnimatedBrainProps {
  width?: number;
  height?: number;
  className?: string;
  interactive?: boolean;
}

export default function AnimatedBrain({
                                        width = 200,
                                        height = 200,
                                        className = '',
                                        interactive = true
                                      }: AnimatedBrainProps) {
  const { colors, isDarkMode } = useTheme();
  const [isAnimating, setIsAnimating] = useState(false);
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
  const [isHovering, setIsHovering] = useState(false);
  const [connections, setConnections] = useState<Array<{
    id: number;
    startX: number;
    startY: number;
    endX: number;
    endY: number;
    animationDelay: number;
    animationDuration: number;
    thickness: number;
    color: string;
  }>>([]);
  const [nodes, setNodes] = useState<Array<{
    id: number;
    x: number;
    y: number;
    size: number;
    animationDelay: number;
    animationDuration: number;
    color: string;
    glow: boolean;
  }>>([]);
  const containerRef = useRef<HTMLDivElement>(null);
  const particlesRef = useRef<Array<{
    x: number;
    y: number;
    size: number;
    speedX: number;
    speedY: number;
    opacity: number;
    color: string;
  }>>([]);

  // Start animation after component mounts
  useEffect(() => {
    setIsAnimating(true);

    // Generate connections and nodes only on the client side
    // Generate random connection points
    const generateConnections = () => {
      const newConnections = [];
      const numConnections = 12;

      for (let i = 0; i < numConnections; i++) {
        const startX = 30 + Math.random() * (width - 60);
        const startY = 30 + Math.random() * (height - 60);
        const endX = 30 + Math.random() * (width - 60);
        const endY = 30 + Math.random() * (height - 60);

        newConnections.push({
          id: i,
          startX,
          startY,
          endX,
          endY,
          animationDelay: Math.random() * 2,
          animationDuration: 2 + Math.random() * 3,
          thickness: 1 + Math.random() * 1.5,
          color: i % 3 === 0 ? colors.accent : (i % 3 === 1 ? colors.primary : colors.secondary)
        });
      }

      return newConnections;
    };

    // Generate random nodes
    const generateNodes = () => {
      const newNodes = [];
      const numNodes = 18;

      for (let i = 0; i < numNodes; i++) {
        const x = 20 + Math.random() * (width - 40);
        const y = 20 + Math.random() * (height - 40);
        const size = 3 + Math.random() * 8;

        newNodes.push({
          id: i,
          x,
          y,
          size,
          animationDelay: Math.random() * 2,
          animationDuration: 1 + Math.random() * 2,
          color: i % 3 === 0 ? colors.accent : (i % 3 === 1 ? colors.primary : colors.secondary),
          glow: Math.random() > 0.7
        });
      }

      return newNodes;
    };

    // Set connections and nodes
    setConnections(generateConnections());
    setNodes(generateNodes());

    // Initialize particles
    if (!particlesRef.current.length) {
      const numParticles = 30;
      for (let i = 0; i < numParticles; i++) {
        particlesRef.current.push({
          x: Math.random() * width,
          y: Math.random() * height,
          size: 1 + Math.random() * 3,
          speedX: (Math.random() - 0.5) * 0.5,
          speedY: (Math.random() - 0.5) * 0.5,
          opacity: 0.1 + Math.random() * 0.4,
          color: i % 3 === 0 ? colors.accent : (i % 3 === 1 ? colors.primary : colors.secondary)
        });
      }
    }

    // Animation frame for particles
    let animationFrameId: number;
    const animateParticles = () => {
      if (!containerRef.current) return;

      const canvas = containerRef.current.querySelector('canvas');
      if (!canvas) return;

      const ctx = (canvas as HTMLCanvasElement).getContext('2d');
      if (!ctx) return;

      // Clear canvas
      ctx.clearRect(0, 0, width, height);

      // Update and draw particles
      particlesRef.current.forEach(particle => {
        // Update position
        particle.x += particle.speedX;
        particle.y += particle.speedY;

        // Boundary check
        if (particle.x < 0 || particle.x > width) particle.speedX *= -1;
        if (particle.y < 0 || particle.y > height) particle.speedY *= -1;

        // Mouse interaction
        if (isHovering && interactive) {
          const dx = mousePosition.x - particle.x;
          const dy = mousePosition.y - particle.y;
          const distance = Math.sqrt(dx * dx + dy * dy);
          const maxDistance = 100;

          if (distance < maxDistance) {
            const force = (maxDistance - distance) / maxDistance;
            particle.speedX += dx * force * 0.01;
            particle.speedY += dy * force * 0.01;

            // Limit speed
            const maxSpeed = 2;
            const speed = Math.sqrt(particle.speedX * particle.speedX + particle.speedY * particle.speedY);
            if (speed > maxSpeed) {
              particle.speedX = (particle.speedX / speed) * maxSpeed;
              particle.speedY = (particle.speedY / speed) * maxSpeed;
            }
          }
        }

        // Draw particle
        ctx.beginPath();
        ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
        ctx.fillStyle = hexToRgba(particle.color, particle.opacity);
        ctx.fill();
      });

      animationFrameId = requestAnimationFrame(animateParticles);
    };

    animateParticles();

    return () => {
      if (animationFrameId) {
        cancelAnimationFrame(animationFrameId);
      }
    };
  }, [colors, width, height, isHovering, mousePosition, interactive]);

  // Handle mouse movement
  const handleMouseMove = (e: React.MouseEvent) => {
    if (!containerRef.current || !interactive) return;

    const rect = containerRef.current.getBoundingClientRect();
    setMousePosition({
      x: e.clientX - rect.left,
      y: e.clientY - rect.top
    });
  };

  // Dynamic styles
  const primaryColor = colors.primary;
  const secondaryColor = colors.secondary;
  const accentColor = colors.accent;
  const gradientColor = colors.gradient;

  return (
      <div
          ref={containerRef}
          className={`relative overflow-hidden ${className} transition-transform duration-500`}
          style={{
            width,
            height,
            transform: isHovering && interactive ? 'scale(1.05)' : 'scale(1)'
          }}
          onMouseMove={handleMouseMove}
          onMouseEnter={() => setIsHovering(true)}
          onMouseLeave={() => setIsHovering(false)}
      >
        {/* Particle canvas */}
        <canvas
            width={width}
            height={height}
            className="absolute top-0 left-0 z-0"
        />

        {/* SVG elements */}
        <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} className="relative z-10">
          {/* Gradient definitions */}
          <defs>
            <linearGradient id="brainGradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor={primaryColor} />
              <stop offset="100%" stopColor={secondaryColor} />
            </linearGradient>

            <filter id="glow">
              <feGaussianBlur stdDeviation="2.5" result="coloredBlur" />
              <feMerge>
                <feMergeNode in="coloredBlur" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>
          </defs>

          {/* Brain outline */}
          <path
              d={`M${width/2},${height/4} 
              C${width/4},${height/5} ${width/5},${height/2} ${width/3},${height*2/3} 
              C${width/2},${height*4/5} ${width*2/3},${height*4/5} ${width*3/4},${height*2/3} 
              C${width*4/5},${height/2} ${width*3/4},${height/5} ${width/2},${height/4}`}
              fill="none"
              stroke="url(#brainGradient)"
              strokeWidth="2.5"
              strokeDasharray={isAnimating ? "5,5" : "0,0"}
              style={{
                animation: isAnimating ? 'dash 3s linear infinite' : 'none',
                filter: 'url(#glow)'
              }}
          />

          {/* Connection lines */}
          {connections.map((connection) => (
              <line
                  key={connection.id}
                  x1={connection.startX}
                  y1={connection.startY}
                  x2={connection.endX}
                  y2={connection.endY}
                  stroke={connection.color}
                  strokeWidth={connection.thickness}
                  strokeDasharray={isAnimating ? "3,3" : "0,0"}
                  style={{
                    animation: isAnimating ? `pulse ${connection.animationDuration}s ease-in-out infinite ${connection.animationDelay}s` : 'none',
                    opacity: 0.7,
                  }}
              />
          ))}

          {/* Nodes */}
          {nodes.map((node) => (
              <circle
                  key={node.id}
                  cx={node.x}
                  cy={node.y}
                  r={node.size}
                  fill={node.color}
                  style={{
                    animation: isAnimating ? `pulse ${node.animationDuration}s ease-in-out infinite ${node.animationDelay}s, 
                                        float ${node.animationDuration + 1}s ease-in-out infinite ${node.animationDelay}s` : 'none',
                    filter: node.glow ? 'url(#glow)' : 'none'
                  }}
              />
          ))}
        </svg>

        {/* CSS for animations */}
        <style jsx>{`
        @keyframes dash {
          to {
            stroke-dashoffset: 20;
          }
        }

        @keyframes pulse {
          0%, 100% {
            opacity: 0.3;
          }
          50% {
            opacity: 0.9;
          }
        }

        @keyframes float {
          0%, 100% {
            transform: translateY(0);
          }
          50% {
            transform: translateY(-5px);
          }
        }
      `}</style>
      </div>
  );
}
