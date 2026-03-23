import xmlrpc.client
host = 'http://35.198.212.102:8069'
common = xmlrpc.client.ServerProxy(f'{host}/xmlrpc/2/common')

users = ['joelsanjay77@gmail.com', 'admin']
passwords = ['kpqA}?G4#D!U7fB', "'kpqA}?G4#D!U7fB'"]

for u in users:
    for p in passwords:
        try:
            res = common.authenticate('odoo', u, p, {})
            print(f"User: {u}, Pwd: {p[:3]}... -> {res}")
        except Exception as e:
            pass
