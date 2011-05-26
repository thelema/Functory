
open Functory.Network
let () = declare_workers ~n:8 "belzebuth"
let () = Functory.Control.set_debug true
open Poly

let is_worker = Array.length Sys.argv >= 2 && Sys.argv.(1) = "-w"

let max_iter = 200 (* nombre maximum d'it�rations *)
let f_max_iter = float max_iter 

(* couleur = interpolation lin�aire entre le rouge (loin) et le vert (pr�s) *)
let interpolation n =
  let f = float n /. f_max_iter in
  Graphics.rgb (truncate ((1. -. f) *. 255.)) (truncate (f *. 255.)) 0

let color xc yc =
  let rec iter i x y =
    if i = max_iter then
      Graphics.black
    else 
      let x2 = x *. x in
      let y2 = y *. y in
      if x2 +. y2 > 4. then
	Graphics.white (*interpolation i*)
      else
	iter (succ i) (x2 -. y2 +. xc) (2. *. x *. y +. yc)
  in
  iter 0 xc yc

let draw xmin xmax ymin ymax w h =
  let m = Array.create_matrix h w Graphics.black in
  let dx = (xmax -. xmin) /. float w in
  let dy = (ymax -. ymin) /. float h in
  for i = 0 to w - 1 do
    for j = 0 to h - 1 do
      let x = xmin +. float i *. dx in
      let y = ymin +. float j *. dy in
      m.(h-1-j).(i) <- color x y
    done
  done;
  m

let worker (xmi, xma, ymi, yma, w, h) = draw xmi xma ymi yma w h

let () = if is_worker then begin Worker.compute worker (); assert false end

let width = int_of_string Sys.argv.(1)
let t = int_of_string Sys.argv.(2)

(* values for the JFLA paper benchmark; see below *)
(* let xmin = -1.1 *)
(* let xmax = -0.8 *)
(* let ymin =  0.2 *)
(* let ymax =  0.4  *)
(* let height = width * 2 / 3 *)

let xmin = -2.0
let xmax =  1.0
let ymin = -1.5
let ymax =  1.5 
let height = width

let tasks = 
  let l = ref [] in
  for j = 0 to t-1 do
    let ymi = ymin +. float j *. (ymax -. ymin) /. float t in
    let yma = ymin +. float (j+1) *. (ymax -. ymin) /. float t in
    l := ((xmin, xmax, ymi, yma, width, height / t), j) :: !l
  done;
  !l

let images = Array.create t ([||] : Graphics.color array array)

let master (_, j) m = images.(j) <- m; []

let () = Master.compute ~master tasks

let () = 
  if true then begin
    Graphics.open_graph (Printf.sprintf " %dx%d" width height);
    let h = height / t in
    Array.iteri
      (fun j m ->
	 let img = Graphics.make_image m in
	 Graphics.draw_image img 0 (j * h))
      images; 
    ignore (Graphics.read_key ())
  end

(* Ocaml bug? *)
(* let () = Graphics.open_graph (Printf.sprintf " %dx%d" width height) *)
(* let master ((_,_,_,_,_,h), j) m = *)
(*   let img = Graphics.make_image m in *)
(*   Graphics.draw_image img 0 (j * h); *)
(*   [] *)
(* let () = Master.compute ~master tasks; ignore (Graphics.read_key ()) *)

(*
run on moloch 

width = 9,000 => height = 6,000 => 54 million pixels

     tasks     timing  speedup

sequential       29.4        1

cores
2       10       15.8        1.86
        30       15.7        1.87 *
       100       16.1        1.83
      1000       19.6        1.50

4       10        9.50       3.09 
        30        8.26       3.56 *
       100        8.37       3.51
      1000       10.6        2.77

8       10        9.40       3.13
        30        4.24       6.93 *
       100        4.38       6.71
      1000        6.86       4.29

network = workers on moloch, remote master on belzebuth

2       10       20.3
        30       18.7 *
       100       19.8
      1000       38.6

4       10       14.4
        30       11.4 *
       100       11.4 *
      1000       20.5

8       10       12.6
        30        7.6
       100        7.5
      1000       11.3
*)


(*
Local Variables: 
compile-command: "make -C ../.. tests/mandelbrot/main_poly.opt"
End: 
*)
