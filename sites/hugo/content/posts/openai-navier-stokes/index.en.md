---
title: "Breaking Navier-Stokes: how OpenAI solved a Millennium Prize Problem in 100 hours"
summary: "An AI-generated proof could resolve a Millennium Prize Problem. What the proposed Navier-Stokes breakdown means, why a negative answer matters, and what remains open."
description: "Understanding OpenAI's proposed Navier-Stokes breakthrough, smooth forcing, finite-time singularities, Lean verification, and the implications for engineering."
date: 2026-09-09T12:00:00-03:00
draft: false
translationKey: "openai-navier-stokes"
slug: "breaking-navier-stokes-how-openai-solved-a-millennium-prize-problem-in-100-hours"
aliases: ["/posts/openai-navier-stokes-millennium-problem/"]
showMath: true
tags: ["AI", "mathematics", "fluid mechanics"]
categories: ["news"]
---
{{< katex >}}

*Based on information available on September 9, 2026.*

When I said I would also share news here, I never imagined the first story would arrive this quickly. Much less that I would be writing about an AI producing a proposed solution to a Millennium Prize Problem.

I had to stop and take that in.

These are problems chosen to represent some of the deepest unresolved questions in mathematics. And now OpenAI has published an AI-generated proof claiming to resolve one of them: the Navier-Stokes existence and smoothness problem. If it withstands scrutiny, this would be a historic mathematical achievement with AI at the center of its discovery. [OpenAI announcement](https://openai.com/index/navier-stokes-solution/), [Millennium Prize Problems](https://www.claymath.org/millennium-problems/).

The announcement also brought a dispute over credit, competing research, and possible use of unpublished work. Those issues deserve attention, but I will leave them outside this article. What I want to understand here is the mathematical breakthrough being claimed, how AI contributed, and why the result matters. [Buckmaster's statement](https://cims.nyu.edu/~tristanb/statement.pdf), [OpenAI's response](https://openai.com/index/navier-stokes-solution/).

According to OpenAI, roughly 10,000 coordinating agents worked for 88 hours to reach the result, followed by another 17 hours for formalization and verification in Lean. The effort used an internal model, computational tools, and human coordination. This was a substantial research operation, and its reported outcome goes far beyond answering an exam question or reproducing a known proof. [OpenAI's account](https://openai.com/index/navier-stokes-solution/).

That is what makes this so remarkable: AI contributing to the creation of mathematical knowledge at this level.

The qualification "proposed" still matters. A published proof, formal verification, and acceptance by the mathematical community are distinct things. But we can be precise about that without losing sight of the scale of the announcement.

So what did the system actually establish? And how can a result saying that equations break down count as solving a million-dollar problem?

## The equations behind moving fluids

Imagine the air flowing around a wing. Its velocity changes from place to place. Pressure pushes it, neighboring layers exchange momentum through viscosity, and the flow carries those changes downstream.

The Navier-Stokes equations describe this balance of momentum. They are part of the mathematical foundation of computational fluid dynamics, or CFD, which engineers use to investigate fluid motion. [NASA's introduction](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/navier-strokes-equation/).

For an incompressible fluid with constant density, we can write:

$$
\frac{\partial \mathbf{u}}{\partial t}
+(\mathbf{u}\cdot\nabla)\mathbf{u}
=-\frac{1}{\rho}\nabla p+\nu\nabla^2\mathbf{u}+\mathbf{f},
\qquad \nabla\cdot\mathbf{u}=0.
$$

Here, **u** is velocity, **p** is pressure, **ρ** is density, **ν** is kinematic viscosity, and **f** is external force per unit mass.

The left side describes acceleration. The right side accounts for pressure, viscosity, and external forcing. The second equation imposes incompressibility. [Mathematical formulation](https://www.claymath.org/wp-content/uploads/2022/06/navierstokes.pdf).

![Reference diagram of the incompressible Navier-Stokes equations and the meaning of their main terms.](navier-stokes-equations.png)

Knowing the equations does not automatically answer every question about their solutions. In particular, calculating a particular flow and proving a guarantee for an entire class of flows are very different tasks.

## Why this became a Millennium Prize Problem

In 2000, the Clay Mathematics Institute selected seven Millennium Prize Problems, assigning one million dollars to each. Navier-Stokes sits alongside P versus NP, the Riemann hypothesis, the Hodge conjecture, the Birch and Swinnerton-Dyer conjecture, Yang-Mills and the mass gap, and the Poincaré conjecture. Clay currently lists Poincaré as solved, following Perelman's work. [The Millennium Prize Problems](https://www.claymath.org/millennium-problems/).

For Navier-Stokes, the central question concerns existence and smoothness in three dimensions. Can initially smooth motion develop a singularity in finite time? "Smooth" is a mathematical regularity condition; it does not simply mean that the flow looks calm.

The official statement offers several alternatives. Its breakdown alternatives, C and D, allow smooth external forces. A counterexample satisfying either can resolve the prize problem without resolving the case with no external forcing. [Official problem statement](https://www.claymath.org/wp-content/uploads/2022/06/navierstokes.pdf).

That detail is essential to understanding the proposed result.

## What the negative answer means

OpenAI's paper constructs a three-dimensional incompressible flow that starts from rest and receives a smooth external force. Its velocity becomes unbounded as a finite time approaches, while total kinetic energy remains bounded.

The construction concentrates motion into a shrinking vortex region and uses oscillatory corrections to keep the forcing smooth. The force itself does not become infinite. This is the substance of the claimed breakdown. [Paper, Theorem 1.1 and Section 2](https://cdn.openai.com/pdf/32d9f210-8b73-45e0-91bc-82a30aef8a9a/navier-stokes.pdf).

A useful way to understand the logic is to distinguish a guarantee from an example.

A guarantee says that every member of a specified class behaves properly. To defeat it, you only need one valid counterexample. You do not need to show that failure is common, likely, or easy to reproduce in a laboratory.

So, if the proof holds, smooth inputs alone do not guarantee smooth evolution throughout this class of forced flows.

Saying that "the equations break themselves" captures some of the surprise. But it needs the qualification that an external force is part of the construction. It would be misleading to describe this as a fluid simply left alone.

![OpenAI's Navier-Stokes vortex: an inward spiral with axial stretching as the singular time approaches.](openai-vortex.png)

*OpenAI's visualization of the proposed flow, showing inward spiraling and axial stretching. See the [original announcement](https://openai.com/index/navier-stokes-solution/) and the [paper, Figure 1](https://cdn.openai.com/pdf/32d9f210-8b73-45e0-91bc-82a30aef8a9a/navier-stokes.pdf).*

## Why discovering a failure is useful

A positive answer would provide a broad guarantee. A negative answer establishes that the assumptions behind that guarantee are insufficient.

That is a meaningful result. It changes what we should try to guarantee and what restrictions we must examine.

The next questions concern the conditions that prevent breakdown. What can be restricted about the forcing? What properties of the initial flow matter? Which quantities, if controlled during evolution, ensure that the solution stays regular?

These questions do not suddenly become easy. But a concrete failure mechanism gives researchers something specific to investigate. It can reveal why an argument fails, what an estimate misses, or which additional assumptions deserve attention.

This is how I would interpret the significance: a valid counterexample would identify a precise limit of a proposed universal guarantee.

## What remains open

There are two different issues here.

First, the prize's formulation. A correct proof satisfying one of its accepted breakdown alternatives would resolve that stated challenge. Using a force does not make it half a solution.

Second, the broader mathematics of fluids. The corresponding question without external forcing is not answered by this construction. Forced breakdown could logically coexist with smooth evolution for every admissible unforced initial flow.

Both cases matter. External forcing is a meaningful part of fluid mechanics, while understanding what a viscous fluid can do from its initial motion alone remains a fundamental question.

There is also the distinction between a mathematical model and a physical fluid. An unbounded mathematical velocity is not a prediction that a real substance literally moves infinitely fast. Interpreting the construction physically requires examining the model's assumptions and their range of applicability.

## Where AI and Lean enter the story

The announcement combines two activities: producing a mathematical argument and checking a formal version of it.

Lean is a proof assistant. Its kernel checks whether a formal statement follows from the definitions, assumptions, and proofs supplied to it. The important remaining task is to establish that those formal statements and assumptions faithfully capture the intended mathematics. [Lean's guide to validating proofs](https://lean-lang.org/doc/reference/latest/ValidatingProofs/).

OpenAI has published a repository containing formalizations and instructions for independent checking. I have not executed those checks myself. [Proof repository](https://github.com/openai/NavierStokesAndEuler).

As of September 9, Clay still labels Navier-Stokes unsolved. Its prize rules require publication in a qualifying outlet, at least two years afterward, and general acceptance by the mathematical community. Those requirements should not be confused with an automatic verdict on a newly released proof. [Current listing](https://www.claymath.org/millennium/navier-stokes-equation/), [prize rules](https://www.claymath.org/millennium-problems/rules/).

The appropriate description at this stage is a proposed resolution with a published formalization, whose broader assessment is still developing.

## What changes for engineering?

I would not discard a validated simulation because of this announcement. Nor would I trust an unvalidated one because a major theorem had been proved.

Engineering confidence comes from examining the calculation we actually performed: its assumptions, numerical behavior, resolution, uncertainties, and comparison with appropriate evidence. A universal smoothness theorem would not eliminate that work, and a counterexample does not replace it.

The immediate impact on an everyday CFD workflow may therefore be small. The longer-term mathematical significance could be substantial.

What draws me to this story is the combination: equations we use in engineering, a guarantee that extends far beyond any individual simulation, and AI systems helping produce arguments that other people can inspect.

If the proof withstands scrutiny, it would answer a major mathematical question. Understanding that answer, its limits, and what to investigate next would still leave plenty of work for us.
