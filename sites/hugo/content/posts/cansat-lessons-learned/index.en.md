---
title: "10 lessons learned designing a CanSat"
summary: "Competing in the AAS CanSat Competition with an autonomously guided parafoil taught me that the hardest engineering challenges were not in the formulas, but in organization, managing uncertainty, and real-world testing."
description: "Systems engineering, team organization, testing strategy, and decision-making lessons from competing in the AAS CanSat Competition."
date: 2026-08-30T13:45:00-03:00
draft: true
translationKey: "cansat-lessons-learned"
slug: "10-lessons-learned-designing-a-cansat"
tags: ["aerospace engineering", "CanSat", "systems engineering", "project management", "lessons learned"]
categories: ["experiences", "projects"]
---

When we started working for the **AAS CanSat Competition**, the objective sounded like a straightforward technical problem: build a soda-can-sized satellite that, after rocket ejection hundreds of meters up, autonomously deploys a parafoil, guides its trajectory using actuators, and lands a fragile egg completely intact.

I quickly realized that the hardest part of the project was not calculating aerodynamic coefficients or coding control laws. It was learning how to coordinate distinct disciplines, make decisions with incomplete information, design tests that produce meaningful answers, and handle everything we did not know we did not know.

Here are ten lessons that process left me with, from our first prototype dropping like a stone to the final integrated flight system.

---

### 1. Point-to-point coordination does not scale: you need a systems view

At the beginning, we split the work across three main disciplines: mechanics and aerodynamics, electronics, and software. Each group moved forward on its own tasks, and communication happened on demand: when we needed board dimensions or servo torque specs, we talked directly to the person in electronics.

That setup works for answering isolated questions, but fails at managing a project. I learned that without someone dedicated to tracking the complete system and setting internal deadlines, subsystems progress at mismatched paces. Point-to-point coordination creates blind spots across interfaces and ensures nobody has a global dependency map until it is too late.

---

### 2. Between analysis paralysis and action confusion

At several points in the project, we found ourselves frozen in doubt, delaying decisions while looking for one more paper, one more simulation run, or one more source to give us absolute certainty. At the other extreme lay the temptation to rush into building blindly without analyzing minimum load paths or constraints.

I discovered that neither extreme works. The key is standing right in the middle: between analysis paralysis and action confusion. You need to set a bounded time window for theoretical analysis, make a well-grounded decision, and move quickly into prototyping. Complete certainty does not exist on paper; it is built as physical prototypes begin interacting with reality.

---

### 3. Respect design milestones (PDR, CDR) as a methodology, not bureaucracy

The competition requires formal design deliverables like the Preliminary Design Review (PDR) and Critical Design Review (CDR). It is easy to view these reviews as administrative overhead, but I came to understand that in practice they are the most effective tool for structuring progress.

Preparing a PDR forced us to freeze the conceptual architecture and verify that high-level numbers closed before cutting material. A CDR compelled us to define every fastener, electrical interface, and material spec. Respecting these milestones prevents the common trap of endless, drifting redesigns during manufacturing.

---

### 4. Document the "why", not just the "what"

In the daily rush of designing and troubleshooting, we logged what dimensions a component had or what fabric we had chosen, but sometimes forgot to write down why that decision had been made and under what assumptions.

I learned that when the need for a design change inevitably appears later (such as trimming 20 grams from the chassis or resizing the wing), having no documented rationale forces you to rethink the entire problem from scratch. Worse, you risk altering a parameter and silently breaking an unstated condition another subsystem relied on.

---

### 5. You do not know what you do not know until hardware meets reality

In models and simulations, everything appeared controlled because we only modeled the phenomena we were aware of. As soon as we assembled our first physical prototype, entire categories of problems emerged that we did not even know existed.

These were not small numerical inaccuracies; they were true unknown unknowns: fabrics that failed to inflate due to the size and shape of the air inlets, suspension lines tangling from material elasticity, or internal aerodynamic backpressure stalling the steering servos. I realized the only way to uncover these blind spots is to build and test early.

---

### 6. The trap of the hyper-realistic first test: isolate variables first

For the first drop test of the Mk 1 parafoil, we attempted to test everything at once from roughly 20 meters up. We hung an exact, full-weight replica of the CanSat underneath, matching mass distribution, center of gravity, and outer geometry to mimic total drag. We wanted a hyper-realistic test on our very first try.

The result was predictable: it dropped like a stone. By stacking so many coupled variables into a single first test, diagnosing the failure was almost impossible. Was it line rigging? Inflation mechanics? Wing loading? Container aerodynamics? The lesson was clear: early tests must isolate variables aggressively. A simple point mass dropped from a lower height would have delivered the same fundamental insights without risking the entire vehicle.

---

### 7. Solving a problem does not finish the job: it unlocks the next one

Complex hardware engineering rarely follows a linear path where fixing a bug makes everything work. I found that it is a layered process: solving one failure merely allows the system to operate long enough to expose the next hidden bottleneck behind it.

When we struggled with initial parafoil inflation, we discovered that the outer line angles were pulling the wingtips inward, closing the wing. Correcting line angles improved inflation, but the canopy still lacked sufficient inflation. That prompted us to investigate the distinction between ground-launched paragliders and air-deployed ram-air parachutes, leading to a complete redesign of larger, angled leading-edge inlets. Each solution unlocked the next level of understanding.

---

### 8. Subsystem convergence: the true challenge of integration

In a multidisciplinary project, subsystems cannot mature in isolation because they must converge at key milestones. Testing autonomous guidance, for instance, required far more than working code: aerodynamics needed a finished parafoil, structures had to have the CanSat ready to house the electronics and connect the parafoil to the system, and electronics needed operational boards and sensors.

I learned that if a single subsystem falls behind, it blocks integrated testing for the entire team. Managing this type of project requires synchronizing delivery schedules so integration does not become a bottleneck that stalls progress.

---

### 9. Invisible engineering: logistics, procurement, academia, and external operations

Designing and programming represented only a fraction of our engineering work. Much of the project's success hinged on tasks rarely covered in textbooks: securing sponsors, managing funds, sourcing specialized materials (Kevlar lines, coated ripstop fabrics, metric fasteners), handling import lead times, and coordinating with university workshop schedules.

Even the logistics of our final tests proved to be a major undertaking. For our final field test, we had to secure airspace restriction permits, coordinate with local airfield management, and organize operations with a drone pilot to execute the drop test from the required altitude. If logistics fail, the hardware never gets off the ground.

---

### 10. Fail fast, succeed faster: embracing early failure

It is natural to hope that a first prototype works flawlessly. But in systems that are novel to the team, the first prototype (Mk 1) rarely flies well; its real purpose is to fail fast so it can teach you exactly what the Mk 2 and Mk 3 need to succeed.

Adopting the mindset of *fail fast, succeed faster* reduces frustration and accelerates development. The difference between a stalled project and a successful mission is not avoiding mistakes, but learning quickly from every failure and applying those lessons to the next iteration.
