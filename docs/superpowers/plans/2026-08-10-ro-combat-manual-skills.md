# RO Combat + Manual Archer Skills Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** RO floating damage numbers, no auto skill cast, manual buttons for all archer cast skills, large projectile skill FX with damage on impact.

**Architecture:** `AutoSkillSystem` becomes a skill resource/CD manager + `tryCastSkill`. Game delays projectile skill damage via `ProjectileComponent.onComplete`. HUD lists castable skills for the active hero class.

**Tech notes:** Prefer Flame `TextComponent` for numbers. No new Higgsfield assets for v1 — scale existing arrow/VFX.

## Task 1: Skill system — no auto cast + tryCastSkill
## Task 2: Damage numbers component + spawn on hit  
## Task 3: Projectile onComplete + delayed skill damage + bigger visuals
## Task 4: HUD skill buttons for archer (+ CD labels)
## Task 5: Tests + APK
