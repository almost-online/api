BEGIN{
use File::Basename;
use File::Spec;
$perl_dir = File::Spec->rel2abs(dirname(__FILE__));
$perl_dir = $perl_dir . "/../perl";
push @INC, $perl_dir;
}

# Import Citrusleaf
use citrusleaf;
use perl_citrusleaf;

citrusleaf::citrusleaf_init();

asc = citrusleaf::citrusleaf_cluster_create();

return_value = citrusleaf::citrusleaf_cluster_add_host($asc, "127.0.0.1", 3000, 1000);

return_value = citrusleaf::citrusleaf_put($asc, "test", "myset",$key_obj, $bins, 2, $cl_wp);

size = citrusleaf::new_intp();
generation = citrusleaf::new_intp();


citrusleaf::citrusleaf_free_bins($bins, $number_bins, $bins_get_all);
citrusleaf::delete_intp($size);
citrusleaf::delete_intp($generation);
citrusleaf::delete_cl_bin_p($bins_get_all);

