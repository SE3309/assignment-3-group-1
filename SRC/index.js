const random = require('random-name');
const crypto = require('crypto');
const {createClient} = require("./database_client");

let addressIds = [];
let branchIds = [];
let userIds = [];
let clientIds = [];
let staffIds = [];

function getRandomName() {
    const hasMiddleName = Math.random() > 0.5;
    return random.first() + (hasMiddleName ? " " + random.middle() : "") + " " + random.last();
}

async function getRandomAddresses(count) {
    const res = await fetch(`https://randommer.io/random-address?number=${count}&culture=en_CA&X-Requested-With=XMLHttpRequest`, {
        method: 'POST'
    });
    return await res.json();
}

async function createAddresses(countInThousands) {
    let addressObjs = [];
    for (let i = 0; i < countInThousands; i++) {
        const addresses = await getRandomAddresses(1000);
        for (const address of addresses) {
            const split = address.split(",");
            const addressObj = {
                street_number: split[0].split(' ')[0].trim(),
                street_name: split[0].split(' ').slice(1).join(' ').trim(),
                postal_code: split[2].split(' ').join('').trim(),
                city: split[3].trim(),
                province: split[4].trim(),
                country: split[5].trim()
            };
            addressObjs.push(addressObj);
        }
    }

    const client = await createClient();
    await client.connect();
    const res = await client.query(
        `INSERT INTO wob.address(street_number, street_name, postal_code, city, province, country)
         SELECT street_number, street_name, postal_code, city, province, country
         FROM jsonb_to_recordset($1::jsonb)
             AS t (
                 street_number integer
                 , street_name text
                 , postal_code character(6)
                 , city text, province text
                 , country text
             )
         RETURNING address_id;`,
        [JSON.stringify(addressObjs)]
    );
    await client.end();

    addressIds = res.rows.map(row => row.address_id);
}

async function createBranches(count) {
    for (let i = 0; i < count; i++) {
        const address = (await getRandomAddresses(1))[0];
        const split = address.split(', ');
        const addressObj = {
            street_number: split[0].split(' ')[0].trim(),
            street_name: split[0].split(' ').slice(1).join(' ').trim(),
            postal_code: split[2].split(' ').join('').trim(),
            city: split[3].trim(),
            province: split[4].trim(),
            country: split[5].trim()
        };
        const client = await createClient();
        await client.connect();
        let res = await client.query(
            `INSERT INTO wob.address(street_number, street_name, postal_code, city, province, country)
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING address_id;`,
            [addressObj.street_number, addressObj.street_name, addressObj.postal_code, addressObj.city, addressObj.province, addressObj.country]
        );
        const addressId = res.rows[0].address_id;

        res = await client.query(
            `INSERT INTO wob.branch(address_id)
             VALUES ($1)
             RETURNING branch_id;`,
            [addressId]
        );
        await client.end();

        branchIds.push(res.rows[0].branch_id);
    }
}

async function hashPassword(password) {
    const salt = process.env.SALT;
    const msgBuffer = new TextEncoder().encode(salt + password);
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

async function createUsers() {
    const users = [];
    const hashedPassword = await hashPassword("password");
    addressIds.forEach(addressId => {
        const name = getRandomName();
        const user = {
            name: name,
            phone_number: `+1 (${Math.floor(Math.random() * 999)}) ${Math.floor(Math.random() * 999)}-${Math.floor(Math.random() * 9999)}`,
            email: (name.split(' ').join('.') + "@gmail.com").toLowerCase(),
            date_of_birth: new Date(1950 + Math.floor(Math.random() * 56), Math.floor(Math.random() * 12), Math.floor(Math.random() * 28)),
            password: hashedPassword,
            address_id: addressId,
            type: Math.random() >= 0.987654320 ? "staff" : "client"
        }
        users.push(user);
    });

    let client = await createClient();
    await client.connect();
    let res = await client.query(
        `INSERT INTO wob.user(name, phone_number, email, date_of_birth, password, address_id)
         SELECT name, phone_number, email, date_of_birth, password, address_id
         FROM jsonb_to_recordset($1::jsonb)
             AS t (
                name text
                , phone_number text
                , email text
                , date_of_birth date
                , password text
                , address_id uuid
             )
         RETURNING user_id;`,
        [JSON.stringify(users)]
    );
    await client.end();
    const userIds = res.rows.map(row => row.user_id);
    users.forEach(function (user, i) {
        user.user_id = userIds[i];
    });

    const clients = users.filter(user => user.type === "client");

    clients.forEach(client => {
        client.student_number = 251_000_000 + Math.floor(Math.random() * 999_999);
        client.status = Math.random() >= 0.3 ? "active" : "inactive";
    })

    client = await createClient();
    await client.connect();
    res = await client.query(
        `INSERT INTO wob.client(student_number, status, user_id)
         SELECT student_number, status, user_id
         FROM jsonb_to_recordset($1::jsonb)
             AS t (
                student_number integer
                , status text
                , user_id uuid
             )
         RETURNING client_id;`,
        [JSON.stringify(clients)]
    );
    await client.end();
    clientIds = res.rows.map(row => row.client_id);

    const staff = users.filter(user => user.type === "staff");

    staff.forEach(staffMember => {

    });
}

async function main() {
    await createAddresses(81).then(_ => console.log("done creating addresses"));
    await createBranches(1).then(_ => console.log("done creating branches"));
    await createUsers().then(_ => console.log("done creating users"));
}

main()
    .then(_ => console.log("done"))
    .catch(e => console.error(e));
