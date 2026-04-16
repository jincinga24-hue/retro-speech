# Quality Gates: AntWar

## After Each Cycle
- [ ] Build passes (`tsc --noEmit` + `vite build`)
- [ ] No TypeScript errors or warnings
- [ ] All tests pass
- [ ] No file exceeds 300 lines
- [ ] No hardcoded secrets
- [ ] Simulation code has zero rendering imports

## Before Ship
- [ ] Manual review of all changes
- [ ] Test coverage > 80% for simulation/
- [ ] 60fps with 200+ ants on screen
- [ ] All docs up to date (PRD, ARCHITECTURE, UI-DESIGN)
- [ ] Event log entries are educational and accurate
