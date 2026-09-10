<?php if (!defined('ABSPATH')) exit; get_header(); ?>
<section class="section"><div class="wrap">
  <?php if (have_posts()): while (have_posts()): the_post(); ?>
    <article style="max-width:760px;margin:0 auto">
      <h1 style="font-size:32px;margin-bottom:16px"><?php the_title(); ?></h1>
      <div class="entry"><?php the_content(); ?></div>
    </article>
  <?php endwhile; else: ?>
    <h1 style="font-size:28px">Eskulapp</h1>
    <p class="sub">Aplikacja eventowa dla organizatorów konferencji medycznych.</p>
    <a class="btn btn-primary" href="<?php echo esc_url(home_url('/')); ?>">Strona główna</a>
  <?php endif; ?>
</div></div></section>
<?php get_footer(); ?>
