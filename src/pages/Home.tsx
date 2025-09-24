import React, { useEffect, useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';
import AttractionCard from '@/components/AttractionCard';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Search, Filter } from 'lucide-react';

interface Attraction {
  id: string;
  title: string;
  description: string;
  speaker: string;
  location: string;
  event_date: string;
  start_time: string;
  end_time: string;
  type: string;
}

const Home = () => {
  const [attractions, setAttractions] = useState<Attraction[]>([]);
  const [userAttractions, setUserAttractions] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [toggleLoading, setToggleLoading] = useState<string | null>(null);
  const { user } = useAuth();
  const { toast } = useToast();

  useEffect(() => {
    fetchAttractions();
    fetchUserAttractions();
  }, [user]);

  const fetchAttractions = async () => {
    try {
      const { data, error } = await supabase
        .from('attractions')
        .select('*')
        .order('event_date', { ascending: true })
        .order('start_time', { ascending: true });

      if (error) throw error;
      setAttractions(data || []);
    } catch (error) {
      console.error('Error fetching attractions:', error);
      toast({
        title: "Erro ao carregar atrações",
        description: "Não foi possível carregar as atrações do evento.",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const fetchUserAttractions = async () => {
    if (!user) return;

    try {
      const { data, error } = await supabase
        .from('user_attractions')
        .select('attraction_id')
        .eq('user_id', user.id);

      if (error) throw error;
      setUserAttractions(data?.map(item => item.attraction_id) || []);
    } catch (error) {
      console.error('Error fetching user attractions:', error);
    }
  };

  const toggleAttractionInAgenda = async (attractionId: string) => {
    if (!user) return;

    setToggleLoading(attractionId);
    const isInAgenda = userAttractions.includes(attractionId);

    try {
      if (isInAgenda) {
        const { error } = await supabase
          .from('user_attractions')
          .delete()
          .eq('user_id', user.id)
          .eq('attraction_id', attractionId);

        if (error) throw error;

        setUserAttractions(prev => prev.filter(id => id !== attractionId));
        toast({
          title: "Removido da agenda",
          description: "A atração foi removida da sua agenda pessoal.",
        });
      } else {
        const { error } = await supabase
          .from('user_attractions')
          .insert({
            user_id: user.id,
            attraction_id: attractionId,
          });

        if (error) throw error;

        setUserAttractions(prev => [...prev, attractionId]);
        toast({
          title: "Adicionado à agenda",
          description: "A atração foi adicionada à sua agenda pessoal!",
        });
      }
    } catch (error) {
      console.error('Error toggling attraction:', error);
      toast({
        title: "Erro ao atualizar agenda",
        description: "Não foi possível atualizar sua agenda. Tente novamente.",
        variant: "destructive",
      });
    } finally {
      setToggleLoading(null);
    }
  };

  const filteredAttractions = attractions.filter(attraction => {
    const matchesSearch = attraction.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         attraction.speaker.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         attraction.description.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesType = typeFilter === 'all' || attraction.type === typeFilter;
    
    return matchesSearch && matchesType;
  });

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-background to-muted/50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">Carregando atrações...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-background to-muted/50">
      <div className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">Atrações do Evento</h1>
          <p className="text-muted-foreground mb-6">
            Explore todas as palestras, workshops e atividades do Ceará Tech Summit 2024
          </p>

          <div className="flex flex-col md:flex-row gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar por título, palestrante ou descrição..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-muted-foreground" />
              <Select value={typeFilter} onValueChange={setTypeFilter}>
                <SelectTrigger className="w-48">
                  <SelectValue placeholder="Filtrar por tipo" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todos os tipos</SelectItem>
                  <SelectItem value="palestra">Palestras</SelectItem>
                  <SelectItem value="workshop">Workshops</SelectItem>
                  <SelectItem value="estande">Estandes</SelectItem>
                  <SelectItem value="networking">Networking</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredAttractions.map((attraction) => (
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
              isInAgenda={userAttractions.includes(attraction.id)}
              onToggleAgenda={toggleAttractionInAgenda}
              loading={toggleLoading === attraction.id}
            />
          ))}
        </div>

        {filteredAttractions.length === 0 && (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">🔍</div>
            <h3 className="text-xl font-semibold mb-2">Nenhuma atração encontrada</h3>
            <p className="text-muted-foreground">
              Tente ajustar os filtros ou termos de busca
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Home;