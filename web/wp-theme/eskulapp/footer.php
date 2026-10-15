<?php if (!defined('ABSPATH')) exit; ?>
<footer class="site-foot">
  <div class="wrap foot-inner">
    <div class="foot-brand"><?php include get_template_directory() . '/parts/logo.php'; ?><span>Eskulapp</span></div>
    <div class="foot-links">
      <a href="<?php echo esc_url(home_url('/')); ?>">Strona główna</a>
      <a href="#funkcje">Funkcje</a>
      <a href="#kontakt">Zapytaj o ofertę</a>
      <?php foreach (eskulapp_store_links() as $s): ?><a href="<?php echo esc_url($s['url']); ?>" target="_blank" rel="noopener"><?php echo esc_html($s['name']); ?></a><?php endforeach; ?>
    </div>
    <div class="foot-copy">&copy; <?php echo esc_html(date('Y')); ?> Eskulapp &middot; System dla uczestników eventów medycznych</div>
  </div>
</footer>
<?php wp_footer(); ?>
</body>
</html>
