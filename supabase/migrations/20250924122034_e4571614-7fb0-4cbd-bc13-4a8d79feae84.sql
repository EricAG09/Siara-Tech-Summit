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
('Talk: Empreender com propósito', 'Empreender com propósito.', 'Arena Educação Empreendedora', 'Arena Educação Empreendedora', '2025-10-10', '14:00', '14:50', 'palestra'),
('Sete pilares de sucesso para internacionalizar sua empresa do Brasil para o mundo através de Portugal', 'Sete pilares de sucesso para internacionalizar sua empresa do Brasil para o mundo através de Portugal.', 'Benício Filho - Atlantic Hub', 'Palco triplo - Ecossistema', '2025-10-10', '15:00', '15:50', 'palestra'),
('Do hype ao controle: Construindo governança responsável para tecnologias de IA', 'Construindo governança responsável para tecnologias de IA.', 'Vládia Pinheiro - Unifor', 'Palco triplo - Inovação', '2025-10-10', '15:00', '15:50', 'palestra'),
('Inovação com sabor e história: O potencial econômico do Maciço de Baturité', 'O potencial econômico do Maciço de Baturité.', 'Elvis Narciel (Mediador), Mônica Farias, Roberto Cariri', 'Arena ELI', '2025-10-10', '15:00', '15:50', 'palestra'),
('Ceará Jogos: como a indústria de games está transformando a região', 'Como a indústria de games está transformando a região.', 'Gabriel Luis - Ascende, Daniel Gularte - Bojogá', 'Arena startups', '2025-10-10', '15:00', '15:40', 'palestra'),
('Aspectos jurídicos relevantes para startups', 'Aspectos jurídicos relevantes para startups.', 'Débora Ximenes - DX Advogados', 'Rede Coworking', '2025-10-10', '15:00', '15:50', 'palestra'),
('Oportunidades para investidores e conselheiros/advisors de Startups', 'Oportunidades para investidores e conselheiros/advisors de Startups.', 'Marcus Vinicius Saraiva - Anjos do Brasil', 'Palco triplo - Negócios', '2025-10-10', '15:00', '15:50', 'palestra'),
('Preparando-se para o futuro: Canva como ferramenta de habilidades digitais', 'Canva como ferramenta de habilidades digitais.', 'Arena Educação Empreendedora', 'Arena Educação Empreendedora', '2025-10-10', '15:00', '15:50', 'palestra'),
('Inovação que gera valor', 'Inovação que gera valor.', 'Allan Costa', 'Palco Summit', '2025-10-10', '16:00', '16:50', 'palestra'),
('Case centro de inovação de Sobral - Cadeia Criativa', 'Case centro de inovação de Sobral - Cadeia Criativa.', 'Messias Aguiar - Cadeia Criativa', 'Arena ELI', '2025-10-10', '16:00', '16:50', 'palestra'),
('Painel Mídia, Marketing e Publicidade', 'Painel Mídia, Marketing e Publicidade.', 'Arena startups', 'Arena startups', '2025-10-10', '16:00', '16:30', 'painel'),
('Como alavancar seu negócio com recursos públicos', 'Como alavancar seu negócio com recursos públicos.', 'Rômulo Ferrer - MonyU', 'Rede Coworking', '2025-10-10', '16:00', '16:50', 'palestra'),
('Painel inovação com sotaque cearense', 'Como jovens lideranças estão apoiando o crescimento dos negócios cearenses.', 'Caio Bessa, Lara Moreira, Matheus Casimiro, Vithoria Rodrigues', 'Arena Educação Empreendedora', '2025-10-10', '16:00', '16:50', 'painel'),
('Painel Moda e Beleza', 'Painel Moda e Beleza.', 'Arena startups', 'Arena startups', '2025-10-10', '16:30', '17:00', 'painel'),
('O novo jogo do relacionamento: Estratégia, dados e inteligência artificial', 'Estratégia, dados e inteligência artificial.', 'Renato Nascimento - Valtech', 'Palco triplo - Negócios', '2025-10-10', '17:00', '17:50', 'palestra'),
('Painel Neoindustrialização e Produtividade Industrial', 'Painel Neoindustrialização e Produtividade Industrial.', 'Arena startups', 'Arena startups', '2025-10-10', '17:00', '17:30', 'painel'),
('Impactos da IA na carreira de jogos', 'Impactos da IA na carreira de jogos.', 'Izequiel Norões - União Cearense de Gamers', 'Rede Coworking', '2025-10-10', '17:00', '17:50', 'palestra'),
('Aspectos práticos de propriedade intelectual para negócios inovadores', 'Aspectos práticos de propriedade intelectual para negócios inovadores.', 'Fábio Barros - INPI', 'Palco triplo - Ecossistema', '2025-10-10', '17:00', '17:50', 'palestra'),
('Inovação que transforma: Como o Cariri está fortalecendo seu ecossistema de inovação', 'Como o Cariri está fortalecendo seu ecossistema de inovação.', 'Arena ELI', 'Arena ELI', '2025-10-10', '17:00', '17:50', 'palestra'),
('Inovação aberta na 3corações: Jornada e insights', 'Jornada e insights da 3corações.', 'Sofia Perez, Thiago Costa - 3 Corações', 'Palco triplo - Inovação', '2025-10-10', '17:00', '17:50', 'palestra'),
('Painel Saúde e Biomedicina', 'Painel Saúde e Biomedicina.', 'Arena startups', 'Arena startups', '2025-10-10', '17:30', '18:00', 'painel'),
('Case polo de educação e inovação do Sertão de Crateús', 'Case polo de educação e inovação do Sertão de Crateús.', 'Alcimar Albuquerque, Diego Ximenes Macedo, Sandro Vagner de Lima', 'Arena ELI', '2025-10-10', '18:00', '18:50', 'palestra'),
('Conexões de Impacto', 'Conexões de Impacto.', 'Arena startups', 'Arena startups', '2025-10-10', '18:00', '18:50', 'painel'),
('Aplicações reais de inteligência artificial para o dia a dia das micro e pequenas empresas', 'Aplicações reais de inteligência artificial para MPEs.', 'Victor Dantas - Moldsoft', 'Rede Coworking', '2025-10-10', '18:00', '18:50', 'palestra'),
('O novo modelo de inovação das startups', 'O novo modelo de inovação das startups.', 'Daniela Klaiman', 'Palco Summit', '2025-10-10', '18:00', '18:50', 'palestra'),
('Startup no caminho certo: O poder da validação antecipada', 'O poder da validação antecipada.', 'Fran Oliveira - FFIT', 'Palco triplo - Inovação', '2025-10-10', '19:00', '19:50', 'palestra'),
('Encontro de Comunidades', 'Encontro de Comunidades.', 'Arena startups', 'Arena startups', '2025-10-10', '19:00', '20:30', 'networking'),
('Case Estação 43 - Ecossistema de Inovação de Londrina/PR', 'Case Estação 43 - Ecossistema de Inovação de Londrina/PR.', 'Hemerson Ravaneda', 'Arena ELI', '2025-10-10', '19:00', '19:50', 'palestra'),
('Entre a inovação e o perigo: Os dilemas da inteligência artificial', 'Os dilemas da inteligência artificial.', 'Alexandre Pinheiro - Energy Telecom', 'Palco triplo - Ecossistema', '2025-10-10', '19:00', '19:50', 'palestra'),
('Da ideia ao impacto: Empreendedorismo universitário como motor da inovação regional', 'Empreendedorismo universitário como motor da inovação regional.', 'Naiderson Lucena - Tec Unifor', 'Arena ELI', '2025-10-10', '20:00', '20:50', 'palestra'),
('ICP e Jornada de Crescimento Recorrente: Caminhos para escalar sua startup', 'Caminhos para escalar sua startup.', 'Diego Bonfim', 'Palco Summit', '2025-10-10', '20:00', '20:50', 'palestra');
