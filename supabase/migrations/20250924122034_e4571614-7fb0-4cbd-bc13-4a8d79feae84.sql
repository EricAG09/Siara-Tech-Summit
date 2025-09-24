-- Create profiles table for user information
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create profiles policies
CREATE POLICY "Users can view their own profile" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Create attractions table
CREATE TABLE public.attractions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  speaker TEXT,
  location TEXT,
  event_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('palestra', 'workshop', 'estande', 'networking')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on attractions (public read)
ALTER TABLE public.attractions ENABLE ROW LEVEL SECURITY;

-- Attractions are public for all authenticated users
CREATE POLICY "Authenticated users can view all attractions" 
ON public.attractions 
FOR SELECT 
TO authenticated
USING (true);

-- Create user_attractions table (user's personal agenda)
CREATE TABLE public.user_attractions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  attraction_id UUID NOT NULL REFERENCES public.attractions(id) ON DELETE CASCADE,
  added_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(user_id, attraction_id)
);

-- Enable RLS on user_attractions
ALTER TABLE public.user_attractions ENABLE ROW LEVEL SECURITY;

-- Users can only see/manage their own agenda
CREATE POLICY "Users can view own agenda" 
ON public.user_attractions 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can add to own agenda" 
ON public.user_attractions 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove from own agenda" 
ON public.user_attractions 
FOR DELETE 
USING (auth.uid() = user_id);

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_attractions_updated_at
    BEFORE UPDATE ON public.attractions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Create function to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name, email)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.email
  );
  RETURN NEW;
END;
$$;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Insert some sample attractions for the Ceará Tech Summit
INSERT INTO public.attractions (title, description, speaker, location, event_date, start_time, end_time, type) VALUES
('Abertura do Ceará Tech Summit 2024', 'Cerimônia de abertura oficial do evento com apresentação da programação', 'Comitê Organizador', 'Auditório Principal', '2024-10-15', '09:00', '10:00', 'palestra'),
('Inteligência Artificial e o Futuro do Trabalho', 'Como a IA está transformando o mercado de trabalho e as profissões do futuro', 'Dr. Ana Silva', 'Sala 1', '2024-10-15', '10:30', '11:30', 'palestra'),
('Workshop: Desenvolvimento Mobile com React Native', 'Hands-on prático para desenvolvimento de aplicações mobile', 'João Santos', 'Lab 1', '2024-10-15', '14:00', '17:00', 'workshop'),
('Estande: Inovações em IoT', 'Demonstração de soluções IoT para cidades inteligentes', 'TechCorp', 'Área de Exposição A', '2024-10-15', '09:00', '18:00', 'estande'),
('Blockchain e Criptomoedas: Além do Hype', 'Aplicações práticas da tecnologia blockchain', 'Maria Costa', 'Sala 2', '2024-10-15', '15:30', '16:30', 'palestra'),
('Networking Coffee Break', 'Momento para networking entre participantes e palestrantes', 'Organização', 'Hall Principal', '2024-10-15', '16:30', '17:00', 'networking'),
('Cybersecurity: Protegendo seu Negócio Digital', 'Estratégias essenciais de segurança cibernética', 'Carlos Mendes', 'Sala 1', '2024-10-16', '09:00', '10:00', 'palestra'),
('Workshop: Cloud Computing na Prática', 'Implementando soluções em nuvem', 'Tech Solutions', 'Lab 2', '2024-10-16', '10:30', '13:30', 'workshop'),
('Startups: Do Ideação ao Scale-up', 'Jornada empreendedora no ecossistema tech', 'Pedro Lima', 'Sala 3', '2024-10-16', '14:00', '15:00', 'palestra'),
('Encerramento e Premiações', 'Cerimônia de encerramento com premiação dos melhores projetos', 'Comitê Organizador', 'Auditório Principal', '2024-10-16', '17:00', '18:00', 'palestra');