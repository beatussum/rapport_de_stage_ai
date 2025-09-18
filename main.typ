#import "@preview/bei-report:0.1.1": *

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

#import "@preview/diagraph:0.3.6": *
#import "@preview/glossy:0.8.0": *

#show: init-glossary.with(toml("glossary.toml"), show-term: emph)
#show: codly-init.with()

#codly(languages: codly-languages, lang-inset: 2pt)

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

==== Une subtilité de la programmation concurrente

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
Que se passe-t-il alors lorque l'on souhaite utiliser plusieurs @fil:pl ?

Afin d'être capable de discriminer les types qui peuvent être utiliser de manière concurrente introduit les @marqueur:pl ```rust Send``` et ```rust Sync```. @bib:the-rust-standard-library

```rust Send``` assure qu'un type peut être envoyé d'un @fil à un autre sans problème. @bib:the-rust-standard-library

```rust Sync``` assure, quant à lui, que la référence d'un type peut être envoyé d'un @fil à un autre sans problème. En d'autres termes, ```rust T``` est ```rust Sync``` si, et seulement si, ```rust &T``` est ```rust Send```. @bib:the-rust-standard-library

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
) <ref:par-iterator>

@ref:par-iterator illustre la similitude entre l'utilisation des itérateurs classiques de la bibliothèque standard d'une part, et, d'autre part, celle des itérateurs parallèles fournis par @rayon.

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

  caption: "Exemple de graphe",
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

= Cas pratique

== Présentation du problème

=== Pertinence

== Solutions séquentielles

=== Parcours en profondeur

=== Implémentation itérative

=== Implémentation récursive

= Parallélisation

== Problématiques

=== La collection associative

== Implémentation des solutions

=== Parcours en largeur

=== Implémentation itérative

=== Itérateur parallèle

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

#glossary(theme: theme, title: "Glossaire")
