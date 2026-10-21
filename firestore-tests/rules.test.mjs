import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { test, after } from 'node:test';
import { doc, getDoc, setDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'fitness-planner-22869',
  firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
});
after(() => env.cleanup());

test('свои данные читаются и пишутся', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice/workouts/w1'), { title: 'Верх' }));
  await assertSucceeds(getDoc(doc(db, 'users/alice/workouts/w1')));
});
test('чужие — нет', async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(getDoc(doc(db, 'users/alice/workouts/w1')));
  await assertFails(setDoc(doc(db, 'users/alice/workouts/w2'), { title: 'x' }));
});
test('без входа — нет', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/alice/workouts/w1')));
});
test('вне users — нет', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'public/x'), { a: 1 }));
});
