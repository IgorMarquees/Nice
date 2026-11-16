/// Caminhos dos assets (logos e banners prontos em assets/).
/// Os banners já trazem o texto na própria arte: o app só os exibe
/// (alguns como link clicável). As imagens "*_inspiracao_*" e
/// "*_nao_usar_*" são só referência de design e não entram no build.
class NiceAssets {
  NiceAssets._();

  static const logoLight = 'assets/NiceB.PSD.png'; // logo branca (fundos escuros)
  static const logoDark = 'assets/NiceP.PSD.png'; // logo escura (fundos claros)

  // Home
  static const homeHero1 = 'assets/web_carrosel_topo_home1_colocar_hyperlink.png';
  static const homeHero2 = 'assets/web_carrosel_topo_home2_colocar_hyperlink.png';
  static const homeEssence = 'assets/sobre_nos_embaixo_carrosel_do_topo_home_colocar_hyperlink.png';

  // Categorias
  static const categoriesTop = 'assets/web_topo_categorias_colocar_hyperlink.png';
  static const categoriesCta = 'assets/web_acima_do_footer_categorias_colocar_hyperlink.png';

  // Novidades
  static const newArrivalsTop = 'assets/web_topo_novidades_colocar_hyperlink.png';

  // Sobre nós
  static const aboutTop = 'assets/web_topo_sobrenos.png';
  static const aboutStrip = 'assets/web_embaixo_topo_sobrenos.png';
  static const aboutCta = 'assets/web_acima_footer_sobrenos.png';

  // Login / cadastro
  static const authBackground = 'assets/fundo_tela_login_e_cadastro.png';
}
