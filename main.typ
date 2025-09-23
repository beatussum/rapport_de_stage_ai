#import "@preview/bei-report:0.1.1": *

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *

#import "@preview/cetz:0.4.2": *
#import "@preview/diagraph:0.3.6": *
#import "@preview/glossy:0.8.0": *
#import "@preview/lovelace:0.3.0": *

#show: init-glossary.with(toml("glossary.toml"), show-term: emph)
#show: codly-init.with()

#show figure.where(kind: raw): fig => {
  set text(size: .798em)
  fig
}

#codly(
  highlighted-default-color: orange.lighten(80%),
  languages: codly-languages,
  lang-outset: (x: .32em, y: .32em),
)

#show: ensimag.with(
  logos: (
    company: image("logos/inria_logo.svg", height: 1fr),
    ensimag: image("logos/ensimag_logo.png", height: 1fr),
  ),
  title: [Algorithmes parallèles de graphe avec Rayon],
  author: (
    name: "Mattéo Rossillol‑‑Laruelle",
    year: [2#super[e] année],
    option: [ISI],
  ),
  period: (
    begin: datetime(year: 2025, month: 05, day: 26),
    end: datetime(year: 2025, month: 07, day: 31),
  ),
  date-fmt: "[day] [month repr:long] [year]",
  company: (
    name: [Centre Inria de l'Université Grenoble Alpes],
    address: [
      655 Avenue de l’Europe \
      38330 Montbonnot-Saint-Martin
    ]
  ),
  internship-tutor: [Frédéric Wagner],
  school-tutor: [Gaelle Calvary],
  abstract: [
    Ce rapport décrit le déroulement d'un stage effectué au @lig pendant l'été 2025.
    Ce stage s'est focalisé sur le développement d'algorithmes parallèles de graphe tout en s'appuyant sur les outils de gestion de parallélisme fournis par la @crate @rayon.

    Dans un premier temps, il a été possible d'explorer l'intérêt du développement de ce type d'outils au travers d'un problème @leetcode. Durant cette phase de prototypage, on a pu constater les avantages apportés par une programmation parallèle ainsi que ses limites.

    À l'issue de la phase précédente, on a pu développé une @crate fournissant une interface générique et permettant donc la résolution parallèle de problème faisant appel à des grahes.

    Enfin, afin d'accroître l'utilisabilité des algorithmes précédemment établis, on a pu concevoir une autre @crate s'interfaçant avec @petgraph.
  ],
  index-terms: (
    "algorithmes de graphes",
    "algorithmes parallèles",
    "ENSIMAG",
    "parallélisme de donnée",
    "rapport de stage",
  ),
  bibliography: bibliography("refs.bib"),
  figure-supplement: [Fig.],
)

#outline(depth: 3)

= Avant-propos

== Contexte

Ce stage s'est tenu au sein de l'équipe @datamove au @lig.

Le @lig est un laboratoire de recherche qui, malgré son nom, se situe à Saint-Martin-d'Hères.
Il s'agit d'un établissement public dont la direction est partagée entre l'@uga, l'@inria et le @cnrs.
Ce laboratoire a été fondé en 2007 avec la mission d'accroître l'efficacité de la recherche en informatique : en effet, le regroupement de plusieurs équipes de spécialisation diverse vise à augmenter les collaborations transversales et le développement de projets interdisciplinaires. @bib:lig

Parmis les équipes du @lig, @datamove a pour sujet d'étude #quote[le mouvement de données pour le calcul haute performance].
En effet, pour les supercalculateurs, la bonne gestion du mouvement de donnée est un enjeu de taille : celui-ci représente, dans les faits, l'une des premières causes de ralentissement.
L'équipe divise son travail en quatre axes de recherche majeurs :
- l'intégration de l'analyse de données et du calcul intensif,
- l'ordonnancement par lot (#emph[batch]) prenant en compte les mouvements de données,
- l'étude empirique de plateformes à grande échelle, et
- la prediction de la disponibilité des ressources. @bib:datamove

== Intérêt de l'objet du stage

D'une part, une multitude de problèmes se résolvent à l'aide d'algorithmes sur des graphes : recherche d'existence de chemin, de plus court chemin ou @sssp, etc..

D'autre part, depuis les alentours des années 2000, les @moore, qui prédisaient l'augmentation constante de la puissance de calcul des processeurs, ne sont plus vérifiées.
En effet, les fabricants commencent depuis quelques années à atteindre les limites physiques.
De cette façon, l'augmentation des performances d'un algorithme ne vient plus, de nos jours, de l'utilisation d'un processeur ayant une fréquence d'horloge plus élevée, mais de la capacité à exploiter aux mieux ses unités de calcul : en d'autres termes, l'enjeu principal est devenu la parallélisation. @bib:sutter

Ansi, bien que de nombreux algorithmes séquentiels existent, ceux dont l'éxécution est parallélisable sont devenus particulièrement intéressants.

== Mission

Au cours des lignes suivantes, on décrira deux algorithmes parallèles :
- recherche d'existence de chemin, et
- recherche de plus court chemin (ou @sssp).

On étudiera ensuite les limites de la parallèlisation.

Enfin, on fournira une interface générique à ces algorithmes.

= Introduction

Avant de commencer, il est nécessaire de présenter certaines notions.

En particulier, l'utilisation du langage de programmation #emph[Rust] sera récurrente tout au long de ce document et, par conséquent, une présentation plus approfondie de celui-ci et des fonctionnalités qu'il offre est nécessaire.

Ensuite, les algorithmes à implémenter seront présentés de manière plus approfondie.

== Concurrence

Avant toute chose, il est important de rappeler que le #emph[parallèlisme] et l'#emph[asynchronisme] désignent tous deux des choses bien distinctes.

=== Parallèlisme

Le #emph[parallèlisme] consiste à exécuter plusieurs tâches simultanéments en s'appuyant sur l'utilisation de plusieurs ressources matérielles (cœurs de processeur, machine, etc.).

Par exemple, calculer la somme des nombres dans $[|1 ; 100|]$, peut être divisé en la somme de la somme des nombres dans $[|1 ; 50|]$, d'une part, et, d'autre part, celle des nombres dans $[|51 ; 100|]$ ; les deux #emph[sous-sommes] peuvent être exécutées en parallèle sur deux ressources matérielles indépendantes.

=== Asynchronisme

Quant à lui, l'#emph[asynchronisme] permet à une tâche de ne pas bloquer l'exécution d'autres tâches pendant qu'elle attend une ressource.
Ce concept est très réguliérement utilisé pour une bonne gestion des opérations entrée/sortie.

Par exemple, une fenêtre graphique doit rester réactive pendant le téléchargement d'un fichier.

Il est important de noter que la clef de voûte de ce concept est l'utilisation d'un ordonnanceur (ou #emph[scheduler]) : il s'agit d'un programme permettant de gérer l'exécution de tâches dont il détermine l'ordre et la durée d'exécution.
Un mécanisme de changement de contexte (ou #emph[context switch]) permet de basculer sur une autre tâche alors que la précédente n'est pas forcément terminée.
De cette façon, un programme asynchrone #emph[peut] être exécuté de manière parallèles, mais #emph[ne doit pas nécessairement] l'être.

Bien que Rust offre des fonctionnalités intéressantes aussi bien en parallèlisme qu'en asynchronisme, c'est bien le premier qui nous intéressera ici.

== Rust et langage concurrent

Rust est un langage de programmation fournissant différentes fonctionnalité qui font de lui un langage idéal pour la programmation concurrente : celles-ci seront détaillées dans les sous-sections suivantes.

#figure(
  ```rust
  fn main() {
    println!("Hello world!");
  }
  ```,
  caption: [Un #emph[Hello world] en Rust],
)

=== Propriété et emprunt

==== Une subtilité de la programmation concurrente <ref:data-race-desc>

Une @data-race survient en programmation concurrente lorsque deux threads ou plus accèdent simultanément à une même variable partagée avec plusieurs accès en écriture.
Cet événement est souvent synonyme de programme non déterminisme et est, par conséquent, source de bogue.

#figure(
  ```cpp
  #include <iostream>
  #include <thread>

  int main() {
    int a = 0;

    std::thread first([&] { a = 1; });
    std::thread second([&] { a = 2; });

    first.join();
    second.join();

    std::cout << a << std::endl;
  }
  ```,
  caption: [Exemple de @data-race en C++],
) <ref:data-race>

Dans @ref:data-race, la valeur de ```cpp a``` peut être aussi bien 1 que 2.

==== Rust et son @borrow-checker

Afin de garantir une sécurité mémoire, Rust introduit deux concepts novateurs à coût nul : la propriété et l'emprunt.

#[
Le principe est le suivant :
- Chaque variable a un unique propriétaire.
- Il ne peux y avoir qu'une seule référence mutable ou#footnote[La langue française étant ambigüe, il s'agit ici d'un #quote[ou] exclusif.] d'un nombre quelconque de référence immutable.
- Les références doivent toujours être valides. @bib:the-rust-programming-language
] <ref:borrow-rules>

Ces garanties sont vérifiées lors de la compilation de manière statique : il n'y a donc aucune opération supplémentaire lors de l'exécution.
Le sous-programme, partie intégrante du compilateur, qui effectue ces vérifications se nomme le @borrow-checker. @bib:the-rust-programming-language

Avec ces règles, il est possible d'éliminer les @data-race et le code @ref:data-race ne pourrait pas être écrit en Rust. @bib:the-rust-programming-language

==== Portée de référence

Il est important de noter que la portée de référence d'une variable est délimité par, d'une part, son introduction et, d'autre part, sa dernière utilisation ; la portée n'est donc pas délimitée par le bloc dans lequel elle se trouve (```rust {}```). @bib:the-rust-programming-language

#figure(
  ```rust
  fn main() {
    let mut a = true; // bool
    let b = &mut a;   // &mut bool
    let c = &mut a;   // &mut bool

    println!("{b}"); // OK
  }
  ```,
  caption: [Portée de référence],
) <ref:reference_scope_ok>

@ref:reference_scope_ok décrit donc un code valide car la variable ```rust c``` n'est plus utilisée au moment où ```rust b``` l'est : il existe donc toujours une seule référence mutable #emph[vivante] sur ```rust a```.

#figure(
  ```rust
  fn main() {
    let mut a = true; // bool
    let b = &mut a;   // &mut bool
    let c = &mut a;   // &mut bool

    println!("{b} {c}"); // KO
  }
  ```,
  caption: [Portée de référence],
) <ref:reference_scope_ko>

Dans le cas de @ref:reference_scope_ko, ```rust b``` et ```rust c``` sont simultanément utilisés lors de l'impression sur la console : il y a donc deux références mutables #emph[vivantes] en même temps et donc erreur.

==== Mutablilité intérieure

Parfois, il n'est pas possible de vérifier statiquement les #link(<ref:borrow-rules>)[règles d'emprunt] ; on peut, par exemple, imaginer l'utilisation d'une ressource créée dynamiquement et partagée en écriture.

On utilise alors un mécanisme de #emph[mutabilité intérieure] afin de vérifier que les #link(<ref:borrow-rules>)[règles précédentes] sont toujours vérifiée. @bib:the-rust-programming-language @bib:the-rust-standard-library

#figure(
  ```rust
  use std::cell::RefCell;

  fn main() {
    let a = RefCell::new(true);
    *a.borrow_mut() = false;
    println!("{}", *a.borrow()); // OK

    let b = a.borrow_mut();
    let c = a.borrow_mut(); // KO
    println!("{} {}", *b, *c);
  }
  ```,
  caption: [Cas de mutabilité intérieure],
) <ref:interior-mutability>

Dans @ref:interior-mutability, on peut voir que, malgré l'immutabilité de ```rust a```, on est capable de modifier son contenu.

Statiquement, les #link(<ref:borrow-rules>)[règles d'emprunt] sont toujours vérifiées (```rust a``` est immutable) ; mais, le contenu de la #emph[cellule] est gérée dynamiquement à l'aide des méthodes ```rust RefCell::borrow``` et ```rust RefCell::borrow_mut```. @bib:the-rust-programming-language @bib:the-rust-standard-library

Ainsi, même quand les #link(<ref:borrow-rules>)[règles d'emprunt] ne peuvent pas êtres vérifiées statiquement, Rust permet leur validation de manière dynamique grâce à certains types spécialisés.

=== ```rust Send``` et ```rust Sync```

Pour l'instant, on s'est intéressé au cas de la programmation synchrone.
Que se passe-t-il alors lorque l'on souhaite utiliser plusieurs @thread:pl ?

Afin d'être capable de discriminer les types qui peuvent être utiliser de manière concurrente introduit les @marqueur:pl ```rust Send``` et ```rust Sync```. @bib:the-rust-standard-library

```rust Send``` assure qu'un type peut être envoyé d'un @thread à un autre sans problème. @bib:the-rust-standard-library

```rust Sync``` assure, quant à lui, que la référence d'un type peut être envoyé d'un @thread à un autre sans problème. En d'autres termes, ```rust T``` est ```rust Sync``` si, et seulement si, ```rust &T``` est ```rust Send```. @bib:the-rust-standard-library

#figure(
  ```rust
  use std::{cell::Cell, thread::spawn};

  fn main() -> std::thread::Result<()> {
    let a = Cell::new(true);
    spawn(|| println!("{a:?}")); // KO
    spawn(move || println!("{a:?}")); // OK
    Ok(())
  }
  ```,
  caption: [Cas pratique avec ```rust Cell```],
) <ref:send-vs-sync>

Dans @ref:send-vs-sync, on peut constater que ```rust Cell``` est ```rust Send```#footnote[Cela s'explique par le fait que ```rust bool``` est ```rust Send```.] mais pas ```rust Sync```.
En effet, une instance ```rust Cell``` détient seule la ressource qu'elle gère ; ainsi, celle-ci peut être déplacer#footnote[```rust move```] sans problème : ```rust Cell``` est donc bien ```rust Send```. A contrario, du fait du mécanisme de mutabilité intérieure, la transférer par référence induirait l'existence de deux accès mutable sur ```rust a``` en même temps du fait du parallèlisme : ```rust Cell``` n'est donc pas ```rust Sync```. @bib:the-rust-standard-library

Grâce à tous les mécanismes expliqués dans les sections précédentes, il est possible d'affirmer que Rust est un langage qui facilite l'écriture concurrente dans le sens où celui-ci est capable d'empêcher les @data-race:pl. @bib:the-rust-programming-language @bib:the-rust-standard-library

=== @rayon

@rayon est une @crate fournissant une interface de haut niveau pour la gestion de tâche parallèles.
Elle s'appuie sur le principe du @divide-and-conquer et du @work-stealing.

Elle peut être utiliser de deux manières différentes :
- une interface de haut niveau à proprement parler qui repose, entre autre, sur des itérateurs parallèles ;
- alternativement, il est possible de découper le travail à effectuer à l'aide de fonctions et structures mis à disposition. @bib:rayon

#figure(
  ```rust
  use rayon::prelude::*;

  fn main() {
    let v = (0..=10).collect::<Vec<_>>();
    let _seq = v.iter().copied().sum::<i32>();
    let _par = v.par_iter().copied().sum::<i32>();
  }
  ```,
  caption: [Exemple d'utilisation de @rayon],
) <ref:rayon-demo>

@ref:rayon-demo illustre la similitude entre l'utilisation des itérateurs classiques de la bibliothèque standard d'une part, et, d'autre part, celle des itérateurs parallèles fournis par @rayon.

De manière générale, une méthode du @trait ```rust Iterator``` a son équivalent dans ```rust ParallelIterator```. @bib:rayon

== Algorithmes de graphe

#figure(
  raw-render(
    ```dot
    digraph {
      a -> b [label = 1]
      a -> c [label = 10]
      b -> e [label = 4]
      c -> d [dir = both label = 2]
      c -> e [label = 3]
      d -> f [label = 5]
      e -> f [label = 20]
      e -> d [label = 6]
    }
    ```
  ),

  caption: [Exemple de graphe],
) <ref:graph>

Nombre de problèmes peuvent être ramenés à une représentation sous la forme de graphe.
Dès que le modèle étudié admet plusieurs entités ayant des relations plus ou moins complexe, la représentation de celui-ci sous la forme d'un graphe peut être pertinente.

On se focalisera ici sur deux algorithmes en particulier.

=== Problème du plus court chemin

#figure(
  table(
    columns: range(7).map(_ => auto),
    table.header([*Sommets*], $a$, $b$, $c$, $d$, $e$, $f$),
    [*Plus court chemin depuis $a$*], $0$, $1$, $10$, $11$, $5$, $17$,
  ),

  caption: [Plus court chemins dans pour @ref:graph],
)

Dans un graphe pondéré, la recherche du plus court chemin consiste à trouver le chemin séparant un sommet d'un autre dont la somme des poids est minimale.

Il s'agit d'un problème très usuel dont la résolution est utile dans beaucoup de domaines tels que dans le transport, la logistique et la livraison, la télécommunication, etc.. Celui-ci admet plusieurs algorithmes de résolution qui peuvent se classer en deux catégorie distinctes :
- la recherche à partir d'un sommet donné (ou @sssp) où l'on détermine la distance minimale séparant un sommet d'origine de tous les autres ;
- la recherche pour tous les couples de sommets où l'on s'intéresse cette fois à tous les couples $(s ; t) in V$. @bib:cormen

Au cours du développement suivant, seule la première catégorie d'algorithme sera abordée.

=== Recherche d'existence de chemin

Dans certains cas, il n'est pas nécessaire de rechercher le chemin optimal en particulier et la simple existence d'un chemin quelconque est suffisante.
Ce problème peut être réduit à un parcours de graphe avec une fin d'exécution potentiellement prématurée.
Il existe deux algorithmes principaux de parcours de graphe :
- celui de parcours en largeur où l'on va explorer le graphe niveau par niveau ;
- celui de parcours en profondeur où, quant à lui, on va explorer chaque de sucesseur en successeur jusqu'à un sommet sans sucesseur. @bib:cormen

Au cours de cette étude, on s'intéressera au parcours en profondeur.

De cette façon, il a été possible d'explorer la notion de programmation concurrente et les raisons qui rendent le Rust un langage adéquat à ce type de programmation, enfin, on a pu succinctement présenter les deux algorithmes que l'on étudiera dans ce papier.

= Cas pratique

Dans un premier temps, on s'intéressera à un petit problème d'informatique faisant intervenir un algorithme sur graphe que l'on cherchera, dans les sections ultérieures, à optimiser au maximum en faisant l'usage notamment de travail parallèle.

@leetcode est une plateforme de problèmes d'informatique en ligne.
Celle-ci est souvent utilisé lors des @technical-interview:pl.
On étudiera ici un problème qui provient de cette plateforme.

Après une présentation exhaustive du problème, on étudiera les différentes solutions séquentielles développées.

== Présentation du problème

#emph[Frog jump] est un problème @leetcode avec le niveau de difficulté #emph[hard], le plus élevée de la plateforme.
Ses étiquettes sont #emph[tableau] et #emph[programmation dynamique]. @bib:frog-jump <ref:frog-jump-intro>

#quote(block: true)[
  Une grenouille traverse la rivière.
  La rivière est divisée en un certain nombre d'unités et, pour chaque unité, une pierre peut être présente.
  Les caractéristiques de la rivière sont données en entrée.
  La grenouille ne peut que sauter aux endroits où une pierre est présente.

  La grenouille, en partant de la première pierre, doit sauter de pierre pour atteindre l'autre rive qui correspond à la dernière position où se trouve également une pierre.

  La taille du saut de la grenouille est égale à sa vitesse $v_k in NN^*$ où $k in NN$ correspond à l'indice du saut.

  À chaque saut, la grenouille ayant une vitesse $v_k$ peut ralentir tel que $v_(k + 1) = max(1, v_k - 1)$, conserver sa vitesse tel que $v_(k + 1) = v_k$ ou accélerer de $v_(k + 1) = min(n - p - 1, v_k + 1)$ où $n >= 2$ est le nombre d'unités et $p in [|0 ; n - 1|]$ la position actuelle de la grenouille.
]

On peut se questionner sur la pertinence du choix de ce problème en particulier.
Pour bien comprendre en quoi celui-ci est intéressant, on va détailler ce qui fait de lui un bon sujet d'étude.

=== Pertinence

Pour commencer, on proposera un modèle mathématique pour représenter le problème.

On pose $(frak(p)_k)_k in {top, bot}^NN$ tel que, pour tout $k in NN$,

$
  frak(p)_k = cases(
    top "s'il y a une pierre à la position" k,
    bot "sinon"
  )
$

On pose l'espace d'état $S = [|0, n - 1|] times [|1, n|]$.

On pose $phi : S -> {top, bot}$ défini par induction pour tout $(p, v) in S$ et $k in {-1, 0, 1}$,

$
  phi (p, v) = cases(
    top "si" p = n - 1,
    bot "si" not frak(p)_p,
    or_(k in {-1, 0, 1}) phi_k (p + v + k, v + k) "sinon",
  )
$

Comme décrit dans l'#link(<ref:frog-jump-intro>)[énoncé du problème], on remarque qu'il s'agit d'un problème de programmation dynamique.
On peut ainsi se ramener à un graphe.

On pose

$
  V &= { (p, v) in S | frak(p)_p } \
  E &= { (a, b) in V^2 | exists k in {-1, 0, 1}, b = a + (k, k) }
$

$G = (V, E)$ est donc le graphe orienté représentatif du problème.

Ainsi, la résolution du problème se résume à montrer l'existence d'un chemin entre le sommet $(0, 1)$ et un des sommets $(n - 1, v)$ où $v in [|1, n|]$.

Pour cette raison, ce problème est tout à fait pertinent dans le cadre de l'étude décrite dans ce document dont l'objectif est, entre autres, déterminer un algorithme parallèle de recherche d'existence de chemin.

Maintenant que l'intérêt de ce problème a été établi, on s'intéresse dorénavant à sa résolution séquentielle.

== Solutions séquentielles

On propose trois solutions séquentielles différentes :
- la première implémente un parcours en profondeur du graphe,
- la seconde itère sur l'espace d'états,
- la dernière suit la première formulation mathématique du problème avec une implémentation récursive.

On étudiera les différentes approches en notant leurs avantages et leurs inconvénients.

Au cours des sections suivantes, on notera $T_s (n)$ (resp. $E_s (n)$) la complexité temporelle (resp. spatialle) dans une situation $s in {"meilleur", "pire"}$ et pour un échantillon de donnée de taille $n >= 2$.

=== Parcours en profondeur

#codly(
  annotations: (
    (
      start: 15,
      end: 23,
      content: block(
        width: 2em,
        rotate(-90deg, reflow: true)[Calcul des successeurs],
      ),
    ),
  ),
  highlights: (
    (
      line: 4,
      start: 11,
      end: 20,
      fill: red,
      label: <ref:dfs-algorithm:hash-map>,
      tag: [(table de hachage)],
    ),
    (
      line: 5,
      start: 11,
      end: 18,
      fill: green,
      label: <ref:dfs-algorithm:stack>,
      tag: [(pile)],
    ),
    (
      line: 22,
      start: 19,
      label: <ref:dfs-algorithm:bin-ops>,
    ),
  ),
)

#figure(
  ```rust
  pub fn solve(input: &Input) -> bool {
    let len = input.len();

    let mut is_visited = HashSet::default();
    let mut to_visit = vec![input.root];

    while let Some(state @ (p, s)) = to_visit.pop() {
        if p == len - 1 {
            return true;
        } else if is_visited.insert(state) {
            let small_speed = s - 1;
            let big_speed = s + 1;
            let big_position = p + big_speed;

            let next = Some((big_position, big_speed))
                .into_iter()
                .chain(
                    (small_speed > 0).then_some((p + small_speed, small_speed)),
                )
                .chain(Some((p + s, s)))
                .filter(|all @ &(p, _)| {
                    (p < len) && input.has_stone[p] && !is_visited.contains(all)
                });

            to_visit.extend(next)
        }
    }

    false
  }
  ```,

  caption: [Implémentation sous la forme d'un parcours en profondeur],
  placement: auto,
  scope: "parent",
) <ref:dfs-algorithm>

Pour @ref:dfs-algorithm, il s'agit tout d'un parcours en profondeur sur le graphe $G$ défini plus haut, bien que celui-ci soit généré de manière @lazy[paresseuse], en partant du sommet $(p = 0, v = 1)$ et que celui-ci dispose d'un arrêt potentiellement précoce, soit dès que l'on trouve un $v in [|1, n|]$ tel que $(p = n - 1, v = v)$ soit atteint.

En Rust, comme dans de nombreux autres langages de programmation, les opérateurs binaires sont @lazy; ainsi, à la ligne @ref:dfs-algorithm:bin-ops, l'ordre des opérandes est très importante : on procède par coût croissant. De cette façon, on effectue
+ une comparaison sur entier dont le coût est négligeable, puis
+ un accès sur un tableau qui plus coûteux car on a une indirection supplémentaire à traiter, et enfin
+ un accès à la table de hachage étant donné le coût non négligeable de la fonction de hâchage et des coûts internes de la table.

Le meilleur cas correspond à une situation dans laquelle on montre l'existence du chemin en ne parcourant qu'une seule #emph[branche] du graphe ; au contraire, la pire est celle qui oblige le parcours entier de $G$.

On en déduit donc que

$
  T_"meilleur" (n) &= o(n) \
  T_"pire" (n) &= \#S \
  &= \# ([|0, n - 1|] times [|1, n|]) \
  &= \# [|0, n - 1|] times \# [|1, n|] \
  &= o(n^2)
$

Par la même analyse, on conclue que

$
  E_"meilleur" (n) &= o(n) \
  E_"pire" &= o(n^2)
$

=== Implémentation itérative

#codly(
  highlighted-lines: range(19, 27),
  annotations: (
    (
      start: 15,
      end: 27,
      content: block(
        width: 2em,
        rotate(-90deg, reflow: true)[Boucle sur $(p, v) in S$],
      ),
    ),
  ),
)

#figure(
  ```rust
  pub fn solve(input: &Input) -> bool {
    let len = input.len();

    let mut is_solvable_with = (0..len)
        .map(|p| (0..len).map(|_| p == len - 1).collect::<Vec<_>>())
        .collect::<Vec<_>>();

    input
        .has_stone
        .iter()
        .copied()
        .enumerate()
        .rev()
        .filter_map(|(i, has_stone)| Some(i).filter(|_| has_stone))
        .for_each(|p| {
            if let Some((first_position, other_positions)) =
                is_solvable_with[p..].split_first_mut()
            {
                first_position[..len - p]
                    .iter_mut()
                    .enumerate()
                    .skip(1)
                    .for_each(|(s, is_solvable)| {
                        *is_solvable = other_positions[s - 1][s]
                            || other_positions[s][s + 1];
                    });
            }
        });

    is_solvable_with[0][1]
  }
  ```,

  caption: [Implémentation itérative],
  placement: auto,
  scope: "parent",
) <ref:iter-algorithm>

Pour @ref:iter-algorithm, on travaille directement sur l'espace d'état $S$.

Le premier appel à ```rust Iterator::for_each``` correspond à la boucle dont le variant est $p in [|0, n - 1|]$ ; le second correspond à celle dont le variant est $v in [|1, n|]$.

On note l'utilisation de ```rust Vec::split_first_mut``` qui nous permet d'écrire dans ```rust is_solvable_with``` à l'indice $(p, v)$ tout en lisant aux indices ${(p + v + k, v + k) | k in {0, 1}}$.

Assez intuitivement, les performances de @ref:iter-algorithm sont très mauvaises comparativement au précédent.
En effet, cet algorithme reconstruit la totalité de l'ensemble $S$ : on en déduit que $T_"meilleur"$ et $E_"meilleur"$ sont quadratiques.

=== Implémentation récursive

#codly(
  annotations: (
    (
      start: 14,
      end: 21,
      content: block(
        width: 2em,
        rotate(-90deg, reflow: true)[Calcul des successeurs],
      ),
    ),
  ),
)

#figure(
  ```rust
  fn phi(
      root @ (p, s): State,
      has_stone: &[bool],
      is_visited: &mut HashMap<State, bool>,
  ) -> bool {
      if !is_visited.contains_key(&root) {
          let len = has_stone.len();

          let small_speed = s - 1;
          let big_speed = s + 1;
          let big_position = p + big_speed;

          let is_solution = (p == len - 1)
              || Some((p + s, s))
                  .into_iter()
                  .chain(
                      (small_speed > 0)
                          .then_some((p + small_speed, small_speed)),
                  )
                  .chain(Some((big_position, big_speed)))
                  .filter(|&(p, _)| (p < len) && has_stone[p])
                  .find(|&root| phi(root, has_stone, is_visited))
                  .is_some();

          is_visited.insert(root, is_solution);
      }

      is_visited.get(&root).copied().unwrap_or(false)
  }

  pub fn solve(input: &Input) -> bool {
      let mut is_visited = HashMap::default();
      phi(input.root, &input.has_stone, &mut is_visited)
  }
  ```,

  caption: [Implémentation récursive],
  placement: auto,
  scope: "parent",
) <ref:rec-algorithm>

Les performances de @ref:rec-algorithm sont comparables avec @ref:dfs-algorithm.
En effet le principe de fonctionnement est globalement le même : la récursion avec @memoization effectue un parcours en profondeur (la pile d'exécution joue le rôle de la pile ```rust to_visit``` de @ref:dfs-algorithm).

Pour cette raison, on peut affirmer que $T_s$ et $E_s$, pour $s in {"meilleur", "pire"}$ ont le même ordre de grandeur. Cependant, le coût de l'appel de fonction (passage d'arguments et embranchement) rend l'approche récursive moins performante que @ref:dfs-algorithm.

On note que la fonction ```rust solve``` est dans les faits une @wrapper-function mettant en place la table de hachage utilisée pour la @memoization.

=== Conclusion

Ainsi, au travers des sections antérieures, on a pu explorer différentes approches de résolution.
On peut conclure, de cette façon, que l'approche abordée dans @ref:dfs-algorithm est la plus prometteuse.
On cherchera, dans les sections suivantes, à améliorer les performances de cet algorithme en s'appuyant sur la parallélisation.

= Parallélisation

Au cours des sous-sections suivantes, on expliquera la démarche qui a permis de mettre en place une solution parallèle du #link(<ref:frog-jump-intro>)[problème étudié].
On s'intéressera, dans un premier temps, aux différentes problématiques qui rendent la parallélisation de @ref:dfs-algorithm difficile ; puis, dans un second temps, on présentera les deux approches développées.

== Problématiques

Après analyse de @ref:dfs-algorithm, on peut remarquer deux difficultés notables quant à la parallélisation de cet algorithme : il s'agit des deux variables en accès mutable que sont
- la table de hachage @ref:dfs-algorithm:hash-map qui permet de retenir les sommets analysés,
- la pile @ref:dfs-algorithm:stack qui liste les sommets à analyser.

Comme expliqué dans la @ref:data-race-desc, le partage de variable mutable dans plusieurs @thread:pl est sujet à @data-race:pl.

== Première approche <ref:par-dfs-algorithm>

Au cours de cette section, on étudiera une approche se basant sur #emph[extrapolation] de l'algorithme séquentiel @ref:dfs-algorithm.

On commencera par étudier les réponses apportées aux deux problématiques précédemment évoquées, puis on présentera l'implémentation proposée de manière plus détaillée.

=== La pile

#figure(
  canvas({
    import draw: anchor, arc, circle, content, group, line

    let arrow-style = (
      mark: (end: "curved-stealth", fill: black),
      stroke: .8pt,
    )

    let before-sizes = (1, 1, 1)
    let after-sizes = (.9, 1.7, 1.3)

    let cylinder(name: none, suffix: none, to, sizes) = group(
      {
        let (a, b, c) = sizes

        // Thirds

        arc(
          (rel: (1.5, -c), to: to),
          start: 0deg,
          stop: -180deg,
          radius: (1.5, .5),
          stroke: (dash: "dashed"),
          name: "third",
        )

        arc(
          (rel: (1.5, -(b + c)), to: to),
          start: 0deg,
          stop: -180deg,
          radius: (1.5, .5),
          stroke: (dash: "dashed"),
          name: "second",
        )

        // Top and bottom

        circle(
          (rel: (0, 0), to: to),
          radius: (1.5, .5),
          name: "top",
        )

        arc(
          (rel: (1.5, -(a + b + c)), to: to),
          start: 0deg,
          stop: -180deg,
          radius: (1.5, .5),
          name: "bottom",
        )

        // Labels

        for (i, pos) in ("bottom", "second", "third").enumerate() {
          content(
            (pos + ".arc-start", 50%, pos + ".arc-end"),
            $#i#suffix$,
          )
        }

        // Horizontal lines

        line("bottom.arc-end", "top.west")
        line("bottom.arc-start", "top.east")
      },

      name: name,
    )

    let cylinders(name: none, suffix: none, before, sizes) = group(
      {
        for (i, (pos, d)) in ("left", "mid", "right").zip(sizes).enumerate() {
          circle(
            (rel: (0, -1), to: before + "." + pos + ".end"),
            radius: (1.5, .5),
            name: pos + "-top",
          )

          arc(
            (rel: (1.5, -d), to: pos + "-top.center"),
            start: 0deg,
            stop: -180deg,
            radius: (1.5, .5),
            name: pos + "-bottom",
          )

          line(pos + "-bottom.arc-end", pos + "-top.west")
          line(pos + "-bottom.arc-start", pos + "-top.east")

          content(
            (pos + "-bottom.center", 40%, pos + "-top.center"),
            $#i#suffix$
          )
        }
      },

      name: name,
    )

    // Before cylindre

    anchor("origin", (0, 0))
    cylinder(name: "before-cylindre", "origin", before-sizes)

    // Split arrows

    group(
      {
        line(
          (rel: (0, -.5), to: "before-cylindre.south"),
          (rel: (0, -2)),
          name: "mid",
          ..arrow-style,
        )

        line(
          (rel: (0, 0), to: "mid.start"),
          (rel: (-3.1, 0), to: "mid.end"),
          name: "left",
          ..arrow-style,
        )

        line(
          (rel: (0, 0), to: "mid.start"),
          (rel: (3.1, 0), to: "mid.end"),
          name: "right",
          ..arrow-style,
        )
      },

      name: "split-arrows",
    )

    // Split cylinders

    cylinders(name: "split", "split-arrows", before-sizes)

    // Transform arrows

    group(
      {
        for (i, pos) in ("left", "mid", "right").enumerate() {
          let to = "split." + pos + "-bottom.south"

          line(
            (rel: (0, -.5), to: to),
            (rel: (0, -2.5), to: to),
            name: pos,
            ..arrow-style,
          )

          content(
            (pos + ".start", 50%, pos + ".end"),
            angle: pos + ".start",
            anchor: "mid",
            align(center)[DFS \ (partiel)],
          )
        }
      },

      name: "transform-arrows",
    )

    cylinders(name: "transform-cylinders", suffix: $'$, "transform-arrows", after-sizes)

    // Merge arrows

    group(
      {
        line(
          (rel: (0, -.5), to: "transform-cylinders.south"),
          (rel: (0, -2)),
          name: "mid",
          ..arrow-style,
        )

        line(
          (rel: (-3, -.5), to: "transform-cylinders.south"),
          "mid.mid",
          stroke: .8pt,
        )

        line(
          (rel: (3, -.5), to: "transform-cylinders.south"),
          "mid.mid",
          stroke: .8pt,
        )
      },

      name: "merge-arrows",
    )

    // After cylinder

    anchor("merge-origin", (rel: (0, -.75), to: "merge-arrows.mid.end"))
    cylinder(suffix: $'$, "merge-origin", after-sizes)
  }),

  caption: [Exécution d'une itération de @ref:stack-algorithm pour $n = 3$],
  placement: auto,
) <ref:stack-algorithm-example>

Afin d'éviter de devoir à partager en écriture une pile, on procédera par réductions successives dont l'algorithme général @ref:stack-algorithm.

#figure(
  pseudocode-list[
    + Créer une pile globale contenant le sommet #emph[racine].
    + *Tant que* la pile globale n'est pas vide *faire*
      + Diviser la pile globale en $n$ piles.
      + *Pour chaque (parallèle)* pile locale *faire*
        + Éxécuter l'algorithme intermédiaire avec la pile locale pour pile de travail.
      + *fin*
      + Fusionner les piles résultantes (en conservant le même ordre que durant la division) en une nouvelle pile globale.
    + *fin*
  ],

  caption: [Algorithme de gestion de piles],
  placement: auto,
) <ref:stack-algorithm>

De cette façon, l'écriture se fait à l'intérieur de chaque @thread et on ne requiert donc pas de gestion de concurrence.

Ce choix d'implémentation permet de ne ne pas trop s'éloigner du fonctionnement de @ref:dfs-algorithm et assure ainsi un certain comportement.
En effet, on remarque que les piles locales sont replacées dans le même ordre que pour leur prélévement : la configuration de la pile globale, après parcours en profondeur partiel, est relativement semblable à celle de @ref:dfs-algorithm pour une itération.

On note que @ref:stack-algorithm est volontairement simplifié : celui-ci ne fait pas mention de la gestion d'arrêt prématurée : cette fonctionnalité est géré par la méthode ```rust ParallelIterator::try_fold``` de @rayon. @bib:rayon

=== La collection associative

@ref:dfs-algorithm comporte également une table de hachage @ref:dfs-algorithm:hash-map qui permet de retenir les sommets déjà étudiés.
Cette table est partagée en écriture pour chaque itération de la boucle principale : cela pose un problème pour la parallélisation pour des raisons d'écritures concurrentes.

@crates-io comporte plusieurs @crate:pl offrant une table de hachage concurrente.
Après quelques @benchmark:pl, la @crate @dashmap s'est révélée être la plus prometteuse.
Son principe de fonctionnement est de contraintre un synchronisme de données à l'aide d'un ```rust RwLock``` @bib:the-rust-standard-library tout en limitant les blocages ; en effet, l'espace des clefs est virtuellement divisé en plusieurs @shard:pl : de cette façon, les blocages ne se font qu'au niveau de ceux-si et cela limite les ralentissements en écriture. @bib:dashmap

Afin d'accroître encore les performances de la table de hachage, une autre fonction de hachage a été choisie : il s'agit de @ahash.
Cette dernière offre de très bonnes performances en contrepartie de quoi elle n'est pas cryptographiquement sécurisée : ce qui, dans le cas présent, ne pose pas de problème. @bib:ahash

=== Implémentation

#codly(
  annotations: (
    (
      start: 19,
      end: 25,
      content: block(
        width: 2em,
        rotate(-90deg, reflow: true)[Calcul des successeurs],
      ),
    ),
  ),
  highlighted-lines: (9, 29, 31),
  highlights: (
    (
      line: 4,
      start: 5,
      end: 14,
      fill: red,
      label: <ref:partial-dfs-algorithm:hash-map>,
      tag: [(table de hachage)],
    ),
    (
      line: 2,
      start: 9,
      end: 16,
      fill: green,
      label: <ref:partial-dfs-algorithm:stack:0>,
      tag: [(pile locale)],
    ),
    (
      line: 39,
      start: 8,
      end: 15,
      fill: green,
      label: <ref:partial-dfs-algorithm:stack:1>,
      tag: [(nouvelle pile locale)],
    ),
  ),
)

#figure(
  ```rust
  fn solve(
      mut to_visit: Vec<State>,
      has_stone: &[bool],
      is_visited: &dashmap::DashSet<State, ahash::RandomState>,
      threshold: usize,
  ) -> Option<Vec<State>> {
    let len = has_stone.len();

    for _ in 0..threshold {
      match to_visit.pop() {
        None => break,

        Some(state @ (p, s)) => {
          if is_visited.insert(state) {
            let small_speed = s - 1;
            let big_speed = s + 1;
            let big_position = p + big_speed;

            let next = Some((big_position, big_speed))
              .into_iter()
              .chain((small_speed > 0).then_some((p + small_speed, small_speed)))
              .chain(Some((p + s, s)))
              .filter(|state @ &(p, _)| {
                (p < len) && has_stone[p] && !is_visited.contains(state)
              });

            for state @ (p, _) in next {
              if p == len - 1 {
                return None;
              } else {
                to_visit.push(state);
              }
            }
          }
        }
      }
    }

    Some(to_visit)
  }
  ```,

  caption: [Parcours en profondeur partiel avec possibilité d'arrêt précoce],
  placement: auto,
  scope: "parent",
) <ref:partial-dfs-algorithm>

@ref:dfs-algorithm:stack requiert l'utilisation d'un algorithme permettant un parcours en profondeur partiel avec possibilité d'arrêt précoce.
Par #quote[partiel], on entend que la boucle principale n'effectue qu'un nombre d'itérations fixé; et, par #quote[possibilité d'arrêt précoce], on décrit la possibilité d'arrêter l'algorithme le plus rapidement possible à partir du moment où on à trouver un sommet tel que, pour un $v in [|1, n|]$, le sommet $(n - 1, v)$ est atteint.

Cet algorithme est présenté en @ref:partial-dfs-algorithm.

Comme présenté en @ref:stack-algorithm et @ref:stack-algorithm-example, @ref:partial-dfs-algorithm:stack:0 fait apparaître une pile locale en entrée qui est, une fois processée, retournée @ref:partial-dfs-algorithm:stack:1.

@ref:partial-dfs-algorithm:9 montre que le parcours en profondeur est bien partiel et n'effectuera qu'un nombre donné d'itérations.

En cas de découverte d'un #emph[sommet de fin] @ref:partial-dfs-algorithm:29, on retourne ```rust None``` afin que ```rust ParallelIterator::try_fold``` puisse cesser l'exécution parallèle le plus tôt possible. @bib:rayon Dans le cas contraire, on ajoute les nouveaux sommets à explorer dans la pile locale.

== Une approche plus @rayon[rayonnante]

#codly(
  annotations: (
    (
      start: 15,
      end: 26,
      content: block(
        width: 2em,
        rotate(-90deg, reflow: true)[Calcul des successeurs],
      ),
    ),
  ),
  highlights: (
    (
      line: 5,
      start: 7,
      end: 16,
      fill: red,
      label: <ref:par-iter-algorithm:hash-map>,
      tag: [(table de hachage)],
    ),
  ),
)

#figure(
  ```rust
  pub fn solve(input: &Input) -> bool {
    use rayon::{iter::walk_tree, prelude::*};

    let is_visited = dashmap::DashSet::<_, ahash::RandomState>::default();

    walk_tree((0, 1), |&state @ (p, s)| {
      is_visited
        .insert(state)
        .then(|| {
          let small_speed = s - 1;
          let big_speed = s + 1;
          let big_position = p + big_speed;

          Some((big_position, big_speed))
            .into_iter()
            .chain((small_speed > 0).then_some((p + small_speed, small_speed)))
            .chain(Some((p + s, s)))
            .filter(|state @ &(p, _)| {
              (p < input.len()) && input.has_stone[p] && !is_visited.contains(state)
            })
        })
        .into_iter()
        .flatten()
    })
    .find_any(|&(p, _)| p == input.len() - 1)
    .is_some()
  }
  ```,

  caption: [Implémentation avec itérateur parallèle],
  placement: auto,
  scope: "parent",
) <ref:par-iter-algorithm>

@rayon offre une autre approche, plus facile de mise en place, grâce à la fonction ```rust walk_tree```.
Celle-ci automatise la construction d'un ```rust ParallelIterator``` en prenant la racine d'un arbre et une @closure qui génère les successeurs (sous la forme d'un ```rust IntoIterator```). @bib:the-rust-standard-library @bib:rayon
Il existe une petite suptilité car on travaille sur un graphe et non arbre : il faut donc @capture[capturer] une table de hachage qui doit donc être, comme pour @ref:par-dfs-algorithm, concurrente afin de retenir les sommets déjà exploré.

Une fois le ```rust ParallelIterator``` créé avec ```rust walk_tree```, il est possible d'appeler ```rust ParallelIterator::find_any``` afin de chercher, pour n'importe quel $v in [|1, n|]$, le sommet $(n - 1, v)$.
On applique ensuite ```rust Option::is_some``` afin de vérifier s'il existe un pareil sommet dans la composante connexe enracinnée en $(0, 1)$. @bib:the-rust-standard-library @bib:rayon

= Analyse des résultats

== Mesure de l'efficacité

== Limites du parallélisme

= Généricité

== Une @crate autonome

== Une meilleure implémentation

= Synthèse générale

== Bilan personnel

== Conclusion technique

= Remerciements

Je remercie, tout d'abord, M. F. Wagner pour m'avoir accepté en temps que stagiaire au sein de l'équipe @datamove, ainsi que pour son aimable aide tout au long de mon séjour au @lig.

Je tiens également à féliciter mes collègues qui ont pu occasionnellement m'aider au cours de ce stage : en particulier, je salue M. P. Kailer et M. V. Trophime pour leur assistance en Rust.

#let theme = (
  ..theme-compact,
  section: (title, body) => {
    heading(numbering: none, title)
    body
  },
  entry: (entry, index, total) => {
    entry.insert("description", eval(entry.description, mode: "markup"))
    (theme-compact.entry)(entry, index, total)
  },
)

#glossary(theme: theme, title: text(size: 10pt)[Glossaire])
