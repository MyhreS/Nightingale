#!/usr/bin/env python3
import json
import os

SONGS_JSON_PATH = os.path.join(os.path.dirname(__file__), "..", "songs", "songs.json")

DURATIONS = {
    "blinding_lights_by_the_weeknd.mp3": 203311,
    "born_to_run_by_bruce_springsteen.mp3": 269975,
    "cant_stop_the_feeling_by_justin_timberlake.mp3": 285910,
    "clocks_by_coldplay.mp3": 255947,
    "dance_monkey_by_tones_and_i.mp3": 209040,
    "dont_stop_beliving_by_journey.mp3": 250305,
    "dynamite_by_taio_cruz.mp3": 202710,
    "happier_by_marshmello_and_bastille.mp3": 218357,
    "hooked_on_a_feeling_by_blue_swede.mp3": 195918,
    "livin_on_a_prayer_by_bon_jovi.mp3": 248894,
    "rock_you_like_a_hurricane_by_scorpions.mp3": 255600,
    "stressed_out_by_twenty_one_pilots.mp3": 202728,
    "the_middle_by_jimmy_eat_world.mp3": 165302,
    "baby_shark_sing_along_by_infantil.mp3": 96156,
    "cotton_eye_john_by_rednex.mp3": 194115,
    "friends_in_low_places_by_garth_brooks.mp3": 265247,
    "gangnam_style_by_psy.mp3": 252290,
    "hey_baby_by_dj_ötzi.mp3": 219559,
    "i_wanna_dance_with_somebody_by_whitney_houston.mp3": 288548,
    "macarena_by_los_del_rio.mp3": 222981,
    "sweet_caroline_by_neil_diamond.mp3": 200376,
    "take_me_home_country_roads_by_john_denver.mp3": 195604,
    "the_cha_cha_slide_dance_by_dj_casper.mp3": 219742,
    "ymca_by_village_people.mp3": 202605,
    "bleed_it_out_by_linkin_park.mp3": 168672,
    "boom_by_pod.mp3": 190824,
    "boulevard_of_broken_dreams_by_green_day.mp3": 262400,
    "bring_me_to_life_by_evanscence.mp3": 243826,
    "cant_hold_us_by_macklemore_and_ryan_lewis.mp3": 423549,
    "cant_stop_by_red_hot_chili_peppers.mp3": 269165,
    "crowd_chant_by_joe_satriani.mp3": 195000,
    "danger_zone_by_kenny_loggins.mp3": 225854,
    "grevling_i_taket_by_knutsen_og_ludvigsen.mp3": 168124,
    "harlam_shake_by_baauer.mp3": 196257,
    "hell_yeah_by_rev_theory.mp3": 249072,
    "higher_ground_by_stevie_wonder.mp3": 191660,
    "highway_to_hell_by_acdc.mp3": 210416,
    "i_like_to_move_it_by_madagascar_5.mp3": 183170,
    "im_an_albatraoz_by_aronchupa.mp3": 147173,
    "immigrant_song_by_led_zeppelin.mp3": 146364,
    "kernkraft_400_by_zombie_nation.mp3": 210494,
    "kickstart_my_heart_by_mötley_crüe.mp3": 282566,
    "lets_get_it_started_by_the_black_eyed_peas.mp3": 217234,
    "mr_saxobeat_by_alexandra_stan.mp3": 193656,
    "ready_for_it_by_taylor_swift.mp3": 208274,
    "rosa_helikopter_by_peaches.mp3": 219036,
    "samsara_by_tungevaag_and_raaban.mp3": 243853,
    "sandstorm_by_darude.mp3": 232385,
    "september_by_earth_wind_and_fire.mp3": 214728,
    "sing_hallelujah_by_dr_alban.mp3": 241554,
    "snakke_litt_by_adminal_p.mp3": 195213,
    "stronger_by_kanye_west.mp3": 266318,
    "survivor_by_destiny_s_child.mp3": 241031,
    "sweet_child_o_mine_by_guns_n_roses.mp3": 302968,
    "the_game_by_motorhead.mp3": 210285,
    "the_phoenix_by_fall_out_boy.mp3": 245786,
    "till_i_collapse_by_eminem.mp3": 297952,
    "we_will_rock_you_by_queen.mp3": 134582,
    "all_i_do_is_win_by_dj_khaled.mp3": 227500,
    "celebrate_by_pitbull.mp3": 191328,
    "chelsea_dagger_by_the_fratellis.mp3": 229485,
    "det_går_likar_no_by_dde.mp3": 195265,
    "freestyler_by_bomfunk_mc_s.mp3": 294687,
    "happy_by_pharrel_williams.mp3": 240718,
    "high_on_life_by_martin_garrix.mp3": 226899,
    "i_love_it_by_icona_pop.mp3": 180062,
    "jump_round_flip_by_dopeman.mp3": 215640,
    "monument_by_keiino.mp3": 188832,
    "song_2_by_blur.mp3": 122618,
    "who_let_the_dogs_out_by_baha_men.mp3": 197459,
    "my_songs_know_what_you_did_in_the_dark_by_fall_out_boy.mp3": 199000,  # Approximate - file was syncing
    "power_by_kanye_west.mp3": 102426,
    "the_final_countdown_by_europe.mp3": 296228,
    "the_pretender_by_foo_fighters.mp3": 270367,
    "tnt_by_acdc.mp3": 216685,
    "turn_down_for_what_by_dj_snake_and_lil_jon.mp3": 216137,
    "we_are_the_champions_by_queen.mp3": 190249,
    "another_one_bites_the_dust_by_queen.mp3": 222746,
    "bad_boys_by_inner_circle.mp3": 229416,
    "benny_hill_by_the_edwin_davids_jazz_band.mp3": 274076,
    "guilty_by_barbra_streisand.mp3": 265926,
    "herregud_by_vidar_villa.mp3": 176483,
    "hit_me_with_your_best_shot_by_pat_benatar.mp3": 172512,
    "low_rider_by_war.mp3": 190872,
    "oops_i_did_it_again_by_britney_spears.mp3": 210600,
    "sitter_på_en_bombe_by_jokke_and_valentinerne.mp3": 152581,
    "smooth_criminal_by_michael_jackson.mp3": 565942,
    "the_imperial_march_by_john_williams.mp3": 185280,
    "why_cant_we_be_friends_by_war.mp3": 240195,
    "best_day_of_my_life_by_american_authors.mp3": 220290,
    "dont_stop_me_now_by_queen.mp3": 217887,
    "good_vibrations_by_marky_mark_and_the_funky_bunch_and_loleatta_holloway.mp3": 269087,
    "we_are_the_champions_victory_by_queen.mp3": 184368,
    "dont_stop_the_party_by_the_black_eyed_peas.mp3": 378566,
    "enter_sandman_by_metallica.mp3": 331049,
    "eye_of_the_tiger_by_survivor.mp3": 244924,
    "levels_by_avicii.mp3": 198452,
    "lose_yourself_by_eminem.mp3": 327549,
    "seven_nation_army_by_the_white_stripes.mp3": 238368,
    "thunderstruck_by_acdc.mp3": 293015,
    "we_will_rock_you_warmup_by_queen.mp3": 134582,
    "welcome_to_the_jungle_by_guns_and_roses.mp3": 279222,
}

def main():
    with open(SONGS_JSON_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    updated_count = 0
    not_found = []
    
    for song in data.get("firebaseSongs", []):
        song_id = song.get("id", "")
        if song_id in DURATIONS:
            song["duration"] = DURATIONS[song_id]
            updated_count += 1
        else:
            not_found.append(song_id)
    
    with open(SONGS_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"Updated {updated_count} songs with durations")
    if not_found:
        print(f"\nSongs not found in duration map:")
        for s in not_found:
            print(f"  - {s}")

if __name__ == "__main__":
    main()

