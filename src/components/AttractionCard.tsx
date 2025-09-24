import React from 'react';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Clock, MapPin, User, Plus, Check } from 'lucide-react';

interface AttractionCardProps {
  id: string;
  title: string;
  description: string;
  speaker: string;
  location: string;
  date: string;
  startTime: string;
  endTime: string;
  type: string;
  isInAgenda: boolean;
  onToggleAgenda: (attractionId: string) => void;
  loading?: boolean;
}

const AttractionCard: React.FC<AttractionCardProps> = ({
  id,
  title,
  description,
  speaker,
  location,
  date,
  startTime,
  endTime,
  type,
  isInAgenda,
  onToggleAgenda,
  loading = false,
}) => {
  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR', { 
      day: '2-digit', 
      month: '2-digit',
      weekday: 'short'
    });
  };

  const formatTime = (timeStr: string) => {
    return timeStr.slice(0, 5);
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'palestra':
        return 'bg-primary text-primary-foreground';
      case 'workshop':
        return 'bg-secondary text-secondary-foreground';
      case 'estande':
        return 'bg-accent text-accent-foreground';
      case 'networking':
        return 'bg-muted text-muted-foreground';
      default:
        return 'bg-gray-500 text-white';
    }
  };

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'palestra':
        return 'Palestra';
      case 'workshop':
        return 'Workshop';
      case 'estande':
        return 'Estande';
      case 'networking':
        return 'Networking';
      default:
        return type;
    }
  };

  return (
    <Card className="h-full hover:shadow-lg transition-all duration-300 border-l-4 border-l-primary">
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <div className="space-y-2 flex-1">
            <div className="flex items-center gap-2">
              <Badge className={getTypeColor(type)}>
                {getTypeLabel(type)}
              </Badge>
              <span className="text-sm text-muted-foreground">
                {formatDate(date)}
              </span>
            </div>
            <h3 className="font-semibold text-lg leading-tight">{title}</h3>
          </div>
          
          <Button
            variant={isInAgenda ? "default" : "outline"}
            size="sm"
            onClick={() => onToggleAgenda(id)}
            disabled={loading}
            className={isInAgenda ? "bg-primary hover:bg-primary/90" : ""}
          >
            {isInAgenda ? (
              <>
                <Check className="w-4 h-4 mr-1" />
                Na Agenda
              </>
            ) : (
              <>
                <Plus className="w-4 h-4 mr-1" />
                Adicionar
              </>
            )}
          </Button>
        </div>
      </CardHeader>

      <CardContent className="space-y-3">
        <p className="text-sm text-muted-foreground line-clamp-2">
          {description}
        </p>

        <div className="flex items-center gap-4 text-sm text-muted-foreground">
          <div className="flex items-center gap-1">
            <Clock className="w-4 h-4" />
            <span>{formatTime(startTime)} - {formatTime(endTime)}</span>
          </div>
          <div className="flex items-center gap-1">
            <MapPin className="w-4 h-4" />
            <span className="truncate">{location}</span>
          </div>
        </div>

        <div className="flex items-center gap-1 text-sm">
          <User className="w-4 h-4 text-muted-foreground" />
          <span className="font-medium">{speaker}</span>
        </div>
      </CardContent>
    </Card>
  );
};

export default AttractionCard;