import React, { useEffect, useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';
import AttractionCard from '@/components/AttractionCard';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { CalendarDays, Clock } from 'lucide-react';

interface AgendaAttraction {
  id: string;
  title: string;
  description: string;
  speaker: string;
  location: string;
  event_date: string;
  start_time: string;
  end_time: string;
  type: string;
  added_at: string;
}

interface GroupedAttractions {
  [date: string]: AgendaAttraction[];
}

const Agenda = () => {
  const [agendaAttractions, setAgendaAttractions] = useState<AgendaAttraction[]>([]);
  const [loading, setLoading] = useState(true);
  const [removeLoading, setRemoveLoading] = useState<string | null>(null);
  const { user } = useAuth();
  const { toast } = useToast();

  useEffect(() => {
    fetchAgendaAttractions();
  }, [user]);

  const fetchAgendaAttractions = async () => {
    if (!user) return;

    try {
      const { data, error } = await supabase
        .from('user_attractions')
        .select(`
          attraction_id,
          added_at,
          attractions:attraction_id (
            id,
            title,
            description,
            speaker,
            location,
            event_date,
            start_time,
            end_time,
            type
          )
        `)
        .eq('user_id', user.id)
        .order('added_at', { ascending: false });

      if (error) throw error;

      const formattedData = data?.map(item => ({
        ...item.attractions,
        added_at: item.added_at,
      })).filter(item => item.id) || [];

      setAgendaAttractions(formattedData);
    } catch (error) {
      console.error('Error fetching agenda:', error);
      toast({
        title: "Erro ao carregar agenda",
        description: "Não foi possível carregar sua agenda pessoal.",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const removeFromAgenda = async (attractionId: string) => {
    if (!user) return;

    setRemoveLoading(attractionId);

    try {
      const { error } = await supabase
        .from('user_attractions')
        .delete()
        .eq('user_id', user.id)
        .eq('attraction_id', attractionId);

      if (error) throw error;

      setAgendaAttractions(prev => prev.filter(item => item.id !== attractionId));
      toast({
        title: "Removido da agenda",
        description: "A atração foi removida da sua agenda pessoal.",
      });
    } catch (error) {
      console.error('Error removing from agenda:', error);
      toast({
        title: "Erro ao remover",
        description: "Não foi possível remover a atração da agenda.",
        variant: "destructive",
      });
    } finally {
      setRemoveLoading(null);
    }
  };

  const groupAttractionsByDate = (attractions: AgendaAttraction[]): GroupedAttractions => {
    return attractions.reduce((groups, attraction) => {
      const date = attraction.event_date;
      if (!groups[date]) {
        groups[date] = [];
      }
      groups[date].push(attraction);
      return groups;
    }, {} as GroupedAttractions);
  };

  const formatDateHeader = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR', { 
      weekday: 'long',
      day: '2-digit', 
      month: 'long',
      year: 'numeric'
    });
  };

  const sortedAttractions = [...agendaAttractions].sort((a, b) => {
    const dateCompare = a.event_date.localeCompare(b.event_date);
    if (dateCompare !== 0) return dateCompare;
    return a.start_time.localeCompare(b.start_time);
  });

  const groupedAttractions = groupAttractionsByDate(sortedAttractions);

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-background to-muted/50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">Carregando sua agenda...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-background to-muted/50">
      <div className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2 flex items-center gap-2">
            <CalendarDays className="w-8 h-8 text-primary" />
            Minha Agenda
          </h1>
          <p className="text-muted-foreground">
            Sua programação personalizada do Siará Tech Summit 2025
          </p>
        </div>

        {agendaAttractions.length === 0 ? (
          <Card className="text-center py-12">
            <CardContent>
              <div className="text-6xl mb-4">📅</div>
              <CardTitle className="mb-2">Sua agenda está vazia</CardTitle>
              <p className="text-muted-foreground mb-4">
                Comece adicionando atrações que deseja participar
              </p>
              <a 
                href="/" 
                className="inline-flex items-center px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors"
              >
                Ver Atrações Disponíveis
              </a>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-8">
            {Object.entries(groupedAttractions).map(([date, attractions]) => (
              <div key={date}>
                <Card className="mb-4">
                  <CardHeader className="pb-3">
                    <CardTitle className="flex items-center gap-2 text-xl">
                      <Clock className="w-5 h-5 text-primary" />
                      {formatDateHeader(date)}
                    </CardTitle>
                    <p className="text-sm text-muted-foreground">
                      {attractions.length} {attractions.length === 1 ? 'atração' : 'atrações'} programadas
                    </p>
                  </CardHeader>
                </Card>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {attractions.map((attraction) => (
                    <AttractionCard
                      key={attraction.id}
                      id={attraction.id}
                      title={attraction.title}
                      description={attraction.description}
                      speaker={attraction.speaker}
                      location={attraction.location}
                      date={attraction.event_date}
                      startTime={attraction.start_time}
                      endTime={attraction.end_time}
                      type={attraction.type}
                      isInAgenda={true}
                      onToggleAgenda={removeFromAgenda}
                      loading={removeLoading === attraction.id}
                    />
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Agenda;