---
title: "What building a CanSat taught me about systems engineering"
summary: "The parafoil was only one part of the problem. Building a CanSat showed me how interfaces, decisions, tests, schedules, and logistics determine whether a multidisciplinary system actually comes together."
description: "Five systems-engineering lessons from designing, integrating, and testing a CanSat with a steerable parafoil recovery system."
date: 2026-10-12T08:00:00-03:00
draft: false
translationKey: "cansat-lessons-learned"
slug: "what-building-a-cansat-taught-me-about-systems-engineering"
featureimagecaption: "Our team at the launch field of the 2026 CanSat Competition, with the CanSat and its parafoil"
tags: ["CanSat", "systems engineering", "project management", "testing", "integration"]
categories: ["experiences", "projects"]
---

The parafoil was the most visible part of our CanSat. It was also only one part of the problem.

![Our team at the launch field of the 2026 CanSat Competition, holding the CanSat, its orange parafoil and the Argentine flag](featured.jpg "Launch day at the 2026 CanSat Competition. The CanSat, its parafoil, and the people who had to make them work together.")

The mission required a soda-can-sized payload to separate from a rocket, deploy a steerable recovery system, navigate toward a target, and release a raw egg close to the ground. Any one of those functions could fail because of a decision made somewhere else in the system.

My work was centered on the aerodynamic design, modeling, manufacturing, and physical testing of the parafoil. That put me directly on several interfaces: the canopy depended on the suspended mass, center of gravity, structural attachment points, servos, electronics, deployment sequence, and guidance logic. A change in any of them could invalidate a calculation or delay a test.

I wrote a separate [technical article about the parafoil](/posts/bringing-an-egg-back-from-space-with-a-paraglider/). This one is about the broader lesson the project left me with: systems engineering is not a final integration step. It is the work of keeping decisions connected from the beginning.

## 1. Interfaces matter more than organizational boundaries

We initially divided the project into mechanics and aerodynamics, electronics, and software. The arrangement looked reasonable because each person could focus on a familiar discipline. The problem was that the CanSat itself did not respect those boundaries.

The parafoil rigging angle depended on the position of the payload center of gravity. That center of gravity depended heavily on where the battery and electronics were mounted. The steering loads affected servo selection, while servo geometry affected the available brake-line travel. Even a change in the structural chassis could alter the drag and the equilibrium glide condition.

Point-to-point conversations solved individual questions, but they did not reveal the complete dependency chain. We needed an explicit view of the interfaces: what each subsystem expected from the others, which values were still assumptions, and who needed to know when one of them changed.

This became painfully clear after manufacturing the second canopy. We discovered that its suspension lines had been calculated using the wrong center-of-gravity location. The wing was finished, but an interface assumption between aerodynamics and structure was not. We recovered by adjusting the rigging and moving the electronics bay upward, but the correction cost time and reduced our margin for further testing.

The lesson was not simply "communicate more." It was to treat interface values as controlled design inputs, not informal information passed between teams.

![Several team members working on the CanSat at once, with the parafoil lines coming out of its base](packing-parafoil.jpg "Many hands on one CanSat. Every subsystem ended up in the same small volume.")

## 2. Reviews and decision records preserve assumptions

The competition required a Preliminary Design Review (PDR) and a Critical Design Review (CDR). At first, those milestones could feel like presentations imposed on top of the real engineering work. In practice, they were useful when they forced us to answer different questions.

The PDR asked whether the proposed architecture could satisfy the mission. The CDR asked whether the actual design was defined well enough to build and integrate. Those are not the same level of certainty.

The reviews were less useful when we documented only the selected value. Writing down that a line had a certain length or that the canopy used a certain area did not preserve the conditions behind the decision. We also needed the reason, the source, the assumptions, and the consequence of changing it.

That distinction matters because a CanSat evolves quickly. A requirement may change, a component may become unavailable, or a mass estimate may become a measured value. Without a decision record, the team has to reconstruct old reasoning under schedule pressure. Worse, somebody can update a number without realizing that another subsystem still depends on the previous one.

Our electronics bay is the example I remember best, precisely because I cannot remember the reason behind it. It started at the bottom of the CanSat for a reason nobody wrote down. When we revisited it later, nothing actually required it to stay there, and moving it to the top raised the center of gravity the way the canopy needed. One line recording why it was placed low would have told us much earlier whether that position was a real constraint or just a leftover.

Good documentation did not mean recording every conversation. It meant preserving the small set of decisions that constrained the system.

## 3. Early tests should isolate uncertainty

Our first parafoil drop tried to reproduce too much of the mission at once. We used a full-weight CanSat replica with its geometry and mass distribution, then released the complete assembly from roughly 20 meters.

It dropped almost like a stone.

The result was dramatic but not very informative. Several explanations were plausible: the inlets might have been too small, the suspension geometry might have folded the wingtips inward, the wing loading might have been too high, the packing sequence might have delayed inflation, or the test might simply have lacked enough altitude.

By coupling all those uncertainties into one drop, we had created a realistic test before we had created a diagnostic one.

The next tests became more useful when each was built around a question. Could the canopy inflate during a manual pull? Did the outer cells remain open under line tension? Did the deployment bag extend the lines before releasing the fabric? Only after those mechanisms behaved consistently did a complete drone release become meaningful.

I stopped thinking of early testing as a reduced version of the final mission. Its purpose was to make one uncertainty observable at a time.

## 4. Integration is a scheduling problem as much as a technical one

An integrated test needs more than individually working subsystems. It needs them to become available together.

We could not test autonomous steering with software alone. We needed a finished canopy, a structure capable of carrying it, installed electronics, functioning sensors, actuators with the correct travel, a safe release mechanism, and enough time to inspect the result before the next attempt.

If any one item arrived late, the entire test window moved. That happened to us with the release mechanism: its electronics were not working in time, and it cost us a drone test. Meanwhile, the teams whose hardware was ready could keep improving their own subsystem, but that local progress did not necessarily reduce mission risk.

This changed how I understood a project schedule. A list of individual deadlines is not enough. The important dates are the moments when several subsystems must converge to answer a system-level question. Those integration milestones need margin for finding a problem, changing the design, and testing again.

![The team integrating the CanSat under the competition tent, with the orange parafoil spread on the table](integration-tent.jpg "Integration under the competition tent. Structure, electronics and parafoil all had to be ready at the same table, at the same time.")

Our limited field opportunities made that margin especially visible. A successful test depended on much more than whether the hardware was theoretically ready on paper.

## 5. Logistics are part of the engineering system

Fabric, Kevlar line, fasteners, batteries, workshop access, sponsors, permits, transport, weather, and the availability of a drone pilot never appeared in the aerodynamic equations. They still determined what we could build and test.

For the final field campaign, we needed an appropriate location, coordination with the airfield, permission to operate, a drone and pilot, acceptable weather, charged equipment, a recovery plan, and a team available at the same time. A delay in any one of those elements could erase the test window.

I had thought of logistics as support work around engineering. The CanSat made it obvious that logistics set real technical constraints. Procurement lead time influenced design choices. Workshop availability influenced manufacturing sequence. Field access influenced the number of iterations we could complete. Operational coordination influenced what could be tested safely.

Our own weak point was simpler. We only started putting together the shopping list once we had reached the final. Deciding not to buy components before qualifying can be a reasonable call. Not having the list ready is not: every item identified late started its delivery time late.

None of that replaces analysis. It defines whether the analysis can become evidence.

![The team at the ground station table on the launch field of the 2026 CanSat Competition](ground-station.jpg "Ground station on launch day. By then, every permit, shipment and test window before it had already shaped what we could fly.")

## What stayed with me

The project taught me more than how to size and manufacture a ram-air canopy. It taught me to look for the assumptions crossing subsystem boundaries, preserve the reasoning behind decisions, design tests around uncertainty, schedule around integration, and treat operations as part of the system.

We did not demonstrate every objective of the original autonomous mission. We did build and test a deployable parafoil that inflated symmetrically and established stable glide, and we learned exactly where our process made that possible or made it harder.

That is the part I would carry into another aerospace project: not a promise that the first design will work, but a better way to discover why it does not, coordinate the correction, and turn the next test into useful evidence.
